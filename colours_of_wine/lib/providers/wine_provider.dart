/* central state management for all wine data (backend integration via service-layer (wine_repository)) */

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wine.dart';
import '../models/wine_description.dart';
import '../data/sample_wines.dart';
import '../services/wine_repository.dart';
import '../services/description_cache.dart';
import '../config/config.dart';
import '../utils/app_constants.dart';

class WineProvider extends ChangeNotifier {
  List<Wine> _wines = [];
  Map<String, int> _wineOrder = {};         // maps wine ID to order index
  Set<String> _initializedWines = {};       // track which wines have been initialized
  static const String _winesKey = 'wines_state';
  
  WineRepository? _wineRepository;
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // initialize repository with Firebase Auth token
  void initializeRepository() {
    _wineRepository = WineRepository(
      baseURL: baseURL,
      getToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');
        final token = await user.getIdToken();
        if (token == null) throw Exception('Failed to get authentication token');
        return token;
      },
    );
  }
  
  List<Wine> get wines => _wines;
  
  List<Wine> _getOrderedWines(List<Wine> wines) {
    final ordered = List<Wine>.from(wines);
    ordered.sort((a, b) {
      final orderA = _wineOrder[a.id] ?? 999999;
      final orderB = _wineOrder[b.id] ?? 999999;
      return orderA.compareTo(orderB);
    });
    return ordered;
  }
  
  List<Wine> get meineWeine => 
      _getOrderedWines(_wines.where((w) => w.category == WineCategory.meineWeine).toList());
  
  List<Wine> get importierteBeschreibungen => 
      _getOrderedWines(_wines.where((w) => w.category == WineCategory.importierteBeschreibungen).toList());
  
  List<Wine> get favoriten => 
      _getOrderedWines(_wines.where((w) => w.isFavorite).toList());

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      initializeRepository();
      
      // load wines from backend (user history) for "meine Weine"
      if (_wineRepository != null && FirebaseAuth.instance.currentUser != null) {
        try {
          final backendWines = await _wineRepository!.getSearchHistory();
          
          // separate wines by category
          final meineWeineList = backendWines;          // only backend wines for "meine Weine"
          // don't load sample wines for "importierte Beschreibungen" - easy fix, so that it can be reversed later if needed
          final otherWines = sampleWines.where((w) =>   // keep sample wines for  "importierte Beschreibungen" ()
            w.category != WineCategory.meineWeine && w.category != WineCategory.importierteBeschreibungen // if we want to use sample wines for imported descriptions, remove this secound condition)
          ).toList();
          
          _wines = [...meineWeineList, ...otherWines];
        } catch (e) {
          debugPrint('Error loading from backend: $e');
          // fallback: use sample wines (now also not enabled)
          _wines = sampleWines.where((w) => w.category != WineCategory.importierteBeschreibungen).toList();
        }
      } else {
        // no auth or repository, also use all sample wines (now also not enabled)
        _wines = sampleWines.where((w) => w.category != WineCategory.importierteBeschreibungen).toList();
      }
      
      _initializedWines.clear();
      
      // initialize order for all wines
      for (int i = 0; i < _wines.length; i++) {
        _wineOrder[_wines[i].id] = i;
      }
      
      await _loadStates();
      
      // mark wines with saved states (non-default checkbox states) as initialized
      for (var wine in _wines) {
        // if any description has isUsedForSummary=false or isExpanded=true, 
        // it means the user has interacted with it, so mark as initialized
        if (wine.descriptions.any((desc) => !desc.isUsedForSummary || desc.isExpanded)) {
          _initializedWines.add(wine.id);
        }
      }
    } catch (e) {
      _errorMessage = 'Error loading data: $e';
      debugPrint(_errorMessage);
      // fallback: use sample wines
      _wines = sampleWines.toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  

  /// reloads the wine history from backend (for "meine Weine")
  Future<void> refreshHistory() async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    if (_wineRepository == null || FirebaseAuth.instance.currentUser == null) {
      debugPrint('Cannot refresh history: no repository or user not authenticated');
      return;
    }
    
    try {
      final backendWines = await _wineRepository!.getSearchHistory();
      // remove old "meine Weine" wines and add new ones
      _wines.removeWhere((w) => w.category == WineCategory.meineWeine);
      _wines.addAll(backendWines);
      // reinitialize order
      final meineWeineList = _wines.where((w) => w.category == WineCategory.meineWeine).toList();
      for (int i = 0; i < meineWeineList.length; i++) {
        _wineOrder[meineWeineList[i].id] = i;
      }
      // don't save to SharedPreferences - "Meine Weine" are stored in backend
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing history: $e');
      _errorMessage = 'Could not refresh history: $e';
      notifyListeners();
    }
  }
  

  /// analyzes wine label images and creates a new wine
  Future<Wine?> analyzeLabel(Uint8List frontBytes, Uint8List backBytes) async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    if (_wineRepository == null) {
      throw Exception('Repository not initialized');
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final wineData = await _wineRepository!.analyzeLabel(frontBytes, backBytes);
      final wine = Wine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: wineData['Name'] ?? '',
        year: wineData['Vintage'] ?? '',
        producer: wineData['Winery'] ?? '',
        region: wineData['Vineyard Location'] ?? '',
        country: wineData['Country'] ?? '',
        category: WineCategory.meineWeine,
        color: '',
        nose: '',
        palate: '',
        finish: '',
        alcohol: 0.0,
        vinification: '',
        foodPairing: '',
        descriptions: [],
      );
      // add wine temporarily (not saved to backend yet, will be saved after generateSummary)
      addWine(wine);
      _isLoading = false;
      notifyListeners();
      return wine;
    } catch (e) {
      _errorMessage = 'Error analyzing label: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  

  /// fetches wine descriptions from web (with caching)
  Future<List<WineDescription>> fetchDescriptions(Wine wine) async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    if (_wineRepository == null) {
      throw Exception('Repository not initialized');
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final cacheKey = wine.toUriComponent();
      // check cache first
      if (DescriptionCache.has(cacheKey) && DescriptionCache.get(cacheKey) != null) {
        final cachedDescriptions = DescriptionCache.get(cacheKey)!;
        debugPrint('Using cached descriptions for: $cacheKey');
        
        final wineDescriptions = cachedDescriptions.asMap().entries.map((entry) {
          return Wine.descriptionFromMap(entry.value, index: entry.key);
        }).toList();
        
        final currentWine = getWineById(wine.id) ?? wine;
        // add descriptions to wine (prepend new ones to existing)
        final updatedWine = currentWine.copyWith(
          descriptions: [...wineDescriptions, ...currentWine.descriptions],
        );
        updateWine(updatedWine);
        
        _isLoading = false;
        notifyListeners();
        return wineDescriptions;
      }
      
      // fetch from internet if not in cache
      final descriptions = await _wineRepository!.fetchDescriptions(wine);
      DescriptionCache.set(cacheKey, descriptions);
      debugPrint('Added descriptions for: $cacheKey to cache');
      
      final wineDescriptions = descriptions.asMap().entries.map((entry) {
        return Wine.descriptionFromMap(entry.value, index: entry.key);
      }).toList();
      
      final currentWine = getWineById(wine.id) ?? wine;
      // add descriptions to wine (prepend new ones to existing)
      final updatedWine = currentWine.copyWith(
        descriptions: [...wineDescriptions, ...currentWine.descriptions],
      );
      updateWine(updatedWine);
      
      _isLoading = false;
      notifyListeners();
      return wineDescriptions;
    } catch (e) {
      _errorMessage = 'Error fetching descriptions: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  

  /// generates summary and image for a wine
  Future<Map<String, dynamic>> generateSummary(Wine wine) async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    
    if (_wineRepository == null) {
      throw Exception('Repository not initialized');
    }
    
    // get current wine from provider to ensure we have the latest state
    final currentWine = getWineById(wine.id) ?? wine;
    
    final selectedDescriptions = currentWine.descriptions
        .where((d) => d.isUsedForSummary)
        .map((d) => currentWine.descriptionToMap(d))
        .toList();
    
    if (selectedDescriptions.isEmpty) {
      throw ArgumentError('At least one description must be selected');
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      
      // prepare complete wine info for backend storage
      // set fromImported based on category if not already set
      final fromImportedValue = currentWine.fromImported ?? 
          (currentWine.category == WineCategory.importierteBeschreibungen ? 'imported' : null);
      
      final wineInfo = {
        'name': currentWine.name,
        'year': currentWine.year,
        'producer': currentWine.producer,
        'region': currentWine.region,
        'country': currentWine.country,
        'descriptions': currentWine.descriptions.map((d) => d.toJson()).toList(),
        'fromImported': fromImportedValue,
      };
      
      final result = await _wineRepository!.generateSummary(
        currentWine,
        selectedDescriptions: selectedDescriptions,
        wineInfo: wineInfo,
      );
      
      // parse result from backend (backend already parsed the sections)
      final imageString = result['image'] as String?;
      final noseText = result['nose'] as String? ?? '';
      final palateText = result['palate'] as String? ?? '';
      final finishText = result['finish'] as String? ?? '';
      final vinificationText = result['vinification'] as String? ?? '';
      final foodPairingText = result['foodPairing'] as String? ?? '';
      
      // store image as data URL
      String? imageDataUrl;
      if (imageString != null && imageString.isNotEmpty) {
        if (imageString.startsWith('data:')) {
          imageDataUrl = imageString;
        } else {
          imageDataUrl = 'data:image/png;base64,$imageString';
        }
      }
      // note: colorHex is not set for stored wines (only for imported wines)
      final updatedWine = currentWine.copyWith(
        nose: noseText,
        palate: palateText,
        finish: finishText,
        vinification: vinificationText.isNotEmpty ? vinificationText : currentWine.vinification,
        foodPairing: foodPairingText.isNotEmpty ? foodPairingText : currentWine.foodPairing,
        imageUrl: imageDataUrl,
        colorHex: null,
        fromImported: fromImportedValue,
      );
      updateWine(updatedWine);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = 'Error generating summary: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  

  /// adds a description from a file
  Future<String> addFileDescription(String wineId, Uint8List bytes, String filename) async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    if (_wineRepository == null) {
      throw Exception('Repository not initialized');
    }
    
    try {
      final text = await _wineRepository!.addFileDescription(bytes, filename);
      final description = WineDescription(
        id: 'file_${DateTime.now().millisecondsSinceEpoch}',
        source: filename,
        text: text,
      );
      addDescription(wineId, description);
      return text;
    } catch (e) {
      _errorMessage = 'Error adding file description: $e';
      notifyListeners();
      rethrow;
    }
  }

  
  /// adds a description from a URL
  Future<void> addURLDescription(String wineId, String url) async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    if (_wineRepository == null) {
      throw Exception('Repository not initialized');
    }
    
    try {
      final (title, text, snippet) = await _wineRepository!.addURLDescription(url);
      final description = WineDescription(
        id: 'url_${DateTime.now().millisecondsSinceEpoch}',
        source: title,
        url: url,
        text: text.isNotEmpty ? text : snippet,
      );
      addDescription(wineId, description);
    } catch (e) {
      _errorMessage = 'Error adding URL description: $e';
      notifyListeners();
      rethrow;
    }
  }
  

  /// deletes a wine from backend and local list
  Future<void> deleteWineFromBackend(String id) async {
    if (_wineRepository == null) {
      initializeRepository();
    }
    
    if (_wineRepository == null) {
      throw Exception('Repository not initialized');
    }
    
    try {
      await _wineRepository!.deleteSearch(id);
      removeWine(id);
      debugPrint('Successfully deleted wine $id from backend and local list');
    } catch (e) {
      debugPrint('Error deleting wine: $e');
      _errorMessage = 'Error deleting wine: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedWinesJson = prefs.getString(_winesKey);
      if (savedWinesJson != null) {
        final savedWinesList = jsonDecode(savedWinesJson) as List<dynamic>;
        final savedWines = savedWinesList
            .map((w) => Wine.fromJson(w as Map<String, dynamic>))
            .toList();
        
        // merge saved states with current wines
        for (var savedWine in savedWines) {
          final index = _wines.indexWhere((w) => w.id == savedWine.id);
          if (index != -1) {
            // update descriptions with saved states
            final currentWine = _wines[index];
            final savedDescriptions = savedWine.descriptions;
            
            // create a map of saved descriptions by id
            final savedDescMap = {
              for (var desc in savedDescriptions) desc.id: desc
            };
            
            // update current descriptions with saved states
            final updatedDescriptions = currentWine.descriptions.map((desc) {
              final savedDesc = savedDescMap[desc.id];
              if (savedDesc != null) {
                return desc.copyWith(
                  isUsedForSummary: savedDesc.isUsedForSummary,
                  isExpanded: savedDesc.isExpanded,
                  text: savedDesc.text, // also restore edited text
                );
              }
              return desc;
            }).toList();
            
            _wines[index] = currentWine.copyWith(
              descriptions: updatedDescriptions,
              isFavorite: savedWine.isFavorite,
            );
          }
        }
      }
    } catch (e) {
      // if loading fails, continue with default data
      debugPrint('Error loading saved states: $e');
    }
  }

  /// Saves state to SharedPreferences (only for non-"Meine Weine" wines)
  /// "Meine Weine" wines are stored in the backend database and loaded from there
  Future<void> _saveStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // only save wines that are NOT in "Meine Weine" category
      final winesToSave = _wines.where((w) => w.category != WineCategory.meineWeine).toList();
      final winesJson = jsonEncode(winesToSave.map((w) => w.toJson()).toList());
      await prefs.setString(_winesKey, winesJson);
    } catch (e) {
      debugPrint('Error saving states: $e');
    }
  }

  /// Adds a wine to the local state (temporarily for "Meine Weine", permanently for other categories)
  /// For "Meine Weine", the wine is only stored in backend after generateSummary() is called
  void addWine(Wine wine) {
    // check if wine already exists to avoid duplicates
    final existingIndex = _wines.indexWhere((w) => w.id == wine.id);
    if (existingIndex != -1) {
      // wine already exists, update it instead of adding
      _wines[existingIndex] = wine;
      // only save to SharedPreferences if not "Meine Weine"
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
      return;
    }
    // wine doesn't exist, add it
    _wines.add(wine);
    // set initial order
    final categoryWines = _wines.where((w) => w.category == wine.category).toList();
    _wineOrder[wine.id] = categoryWines.length - 1;
    // only save to SharedPreferences if not "Meine Weine"
    if (wine.category != WineCategory.meineWeine) {
      _saveStates();
    }
    notifyListeners();
  }

  void removeWine(String id) {
    final wineIndex = _wines.indexWhere((w) => w.id == id);
    if (wineIndex == -1) {
      // wine not found, nothing to remove
      return;
    }
    final wine = _wines[wineIndex];
    _wines.removeWhere((w) => w.id == id);
    _wineOrder.remove(id);
    // only save to SharedPreferences if not "Meine Weine"
    if (wine.category != WineCategory.meineWeine) {
      _saveStates();
    }
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _wines.indexWhere((w) => w.id == id);
    if (index != -1) {
      final wine = _wines[index];
      _wines[index] = wine.copyWith(isFavorite: !wine.isFavorite);
      // only save to SharedPreferences if not "Meine Weine"
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  /// Updates a wine in local state
  /// For "Meine Weine", only updates local state (backend is updated via generateSummary)
  void updateWine(Wine wine) {
    final index = _wines.indexWhere((w) => w.id == wine.id);
    if (index != -1) {
      _wines[index] = wine;
      // only save to SharedPreferences if not "Meine Weine"
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  Wine? getWineById(String id) {
    try {
      return _wines.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Toggles all descriptions for a wine to be used in summary generation.
  /// If all are selected, deselects all. Otherwise, selects all.
  void selectAllDescriptions(String wineId) {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      
      // Check if all descriptions are currently selected
      final allSelected = wine.descriptions.isNotEmpty && 
          wine.descriptions.every((desc) => desc.isUsedForSummary);
      
      // Toggle: if all selected, deselect all; otherwise select all
      final newValue = !allSelected;
      final updatedDescriptions = wine.descriptions.map((desc) {
        return desc.copyWith(isUsedForSummary: newValue);
      }).toList();
      
      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  void toggleDescriptionForSummary(String wineId, String descriptionId, bool value) {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      final updatedDescriptions = wine.descriptions.map((desc) {
        if (desc.id == descriptionId) {
          return desc.copyWith(isUsedForSummary: value);
        }
        return desc;
      }).toList();
      
      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  Future<void> updateDescriptionText(String wineId, String descriptionId, String text) async {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      final updatedDescriptions = wine.descriptions.map((desc) {
        if (desc.id == descriptionId) {
          return desc.copyWith(text: text);
        }
        return desc;
      }).toList();

      final updatedWine = wine.copyWith(descriptions: updatedDescriptions);
      _wines[wineIndex] = updatedWine;
      
      // save to backend for "Meine Weine" wines
      if (wine.category == WineCategory.meineWeine) {
        if (_wineRepository == null) {
          initializeRepository();
        }
        if (_wineRepository != null && FirebaseAuth.instance.currentUser != null) {
          try {
            await _wineRepository!.updateWineInfo(updatedWine);
            debugPrint('Successfully updated description in backend for wine: $wineId');
          } catch (e) {
            debugPrint('Error updating description in backend: $e');
            _errorMessage = 'Error saving description: $e';
            notifyListeners();
            // don't rethrow - local state is already updated
          }
        }
      } else {
        // only save to SharedPreferences if not "Meine Weine"
        _saveStates();
      }
      notifyListeners();
    }
  }

  void toggleDescriptionExpanded(String wineId, String descriptionId, bool value) {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      final updatedDescriptions = wine.descriptions.map((desc) {
        if (desc.id == descriptionId) {
          return desc.copyWith(isExpanded: value);
        }
        return desc;
      }).toList();

      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  void enableAllDescriptionsForSummary(String wineId) {
    // only initialize if not already done (to preserve saved checkbox states)
    if (_initializedWines.contains(wineId)) {
      return;
    }
    
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      
      // always set all to true on first open
      final updatedDescriptions = wine.descriptions.map((desc) {
        return desc.copyWith(isUsedForSummary: true);
      }).toList();
      
      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      _initializedWines.add(wineId);
      notifyListeners();
    }
  }

  /// enable default number of descriptions for summary based on user settings
  Future<void> enableDefaultDescriptionsForSummary(String wineId) async {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex == -1) {
      debugPrint('Wine not found: $wineId');
      return;
    }
    
    final wine = _wines[wineIndex];
    final allUnselected = wine.descriptions.every((desc) => !desc.isUsedForSummary);
    
    if (_initializedWines.contains(wineId) && !allUnselected) {
      return;
    }
    
    if (wine.descriptions.isEmpty) {
      debugPrint('Wine has no descriptions: $wineId');
      return;
    }
    
    int defaultCount = AppConstants.defaultSelectedDescriptionsCount;
    try {
      final prefs = await SharedPreferences.getInstance();
      defaultCount = prefs.getInt(AppConstants.defaultDescriptionCountKey) ?? 
                     AppConstants.defaultSelectedDescriptionsCount;
    } catch (e) {
      debugPrint('Error loading default description count: $e');
    }
    
    final actualCount = wine.descriptions.length;
    final countToEnable = defaultCount > actualCount ? actualCount : defaultCount;
    
    // enable only the first N descriptions based on default count
    final updatedDescriptions = wine.descriptions.asMap().entries.map((entry) {
      final index = entry.key;
      final desc = entry.value;
      return desc.copyWith(isUsedForSummary: index < countToEnable);
    }).toList();
    
    _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
    if (wine.category != WineCategory.meineWeine) {
      _saveStates();
    }
    _initializedWines.add(wineId);
    notifyListeners();
    
    debugPrint('Enabled $countToEnable out of ${wine.descriptions.length} descriptions for wine $wineId');
  }


  void reorderWinesInCategory(WineCategory category, List<String> wineIds, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    if (oldIndex >= 0 && oldIndex < wineIds.length && 
        newIndex >= 0 && newIndex < wineIds.length) {
      final movedId = wineIds.removeAt(oldIndex);
      wineIds.insert(newIndex, movedId);
      
      // update order indices for all wines in this category
      for (int i = 0; i < wineIds.length; i++) {
        _wineOrder[wineIds[i]] = i;
      }
      notifyListeners();
    }
  }

  List<Wine> getSortedWines(List<Wine> wines, String sortBy) {
    final sorted = List<Wine>.from(wines);
    if (sortBy == 'name') {
      sorted.sort((a, b) => a.displayName.compareTo(b.displayName));
    } else if (sortBy == 'year') {
      sorted.sort((a, b) {
        final yearA = int.tryParse(a.year) ?? 0;
        final yearB = int.tryParse(b.year) ?? 0;
        return yearB.compareTo(yearA); // descending (newest first)
      });
    }
    return sorted;
  }

  bool isNewWine(Wine wine) {
    // a wine is "new" if it doesn't have a summary (nose, palate, finish are empty)
    return wine.nose.isEmpty && wine.palate.isEmpty && wine.finish.isEmpty;
  }

  void addDescription(String wineId, WineDescription description) {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      final updatedDescriptions = [description, ...wine.descriptions];
      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      // only save to SharedPreferences if not "Meine Weine"
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  void removeDescription(String wineId, String descriptionId) {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      final updatedDescriptions = wine.descriptions.where((d) => d.id != descriptionId).toList();
      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      // only save to SharedPreferences if not "Meine Weine"
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }

  void reorderDescriptions(String wineId, int oldIndex, int newIndex) {
    final wineIndex = _wines.indexWhere((w) => w.id == wineId);
    if (wineIndex != -1) {
      final wine = _wines[wineIndex];
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final updatedDescriptions = List<WineDescription>.from(wine.descriptions);
      final item = updatedDescriptions.removeAt(oldIndex);
      updatedDescriptions.insert(newIndex, item);
      _wines[wineIndex] = wine.copyWith(descriptions: updatedDescriptions);
      // only save to SharedPreferences if not "Meine Weine"
      if (wine.category != WineCategory.meineWeine) {
        _saveStates();
      }
      notifyListeners();
    }
  }
}
