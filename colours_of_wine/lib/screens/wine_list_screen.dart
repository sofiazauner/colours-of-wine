/* displays list of wines with sort/filter options and add button */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/wine.dart';
import '../providers/wine_provider.dart';
import '../dialogs/add_wine_dialog.dart';
import 'wine_detail_screen.dart';
import 'wine_descriptions_screen.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import '../utils/snackbar_messages.dart';

class WineListScreen extends StatefulWidget {
  final String title;
  final WineCategory category;
  final List<Wine> wines;

  const WineListScreen({
    super.key,
    required this.title,
    required this.category,
    required this.wines,
  });

  @override
  State<WineListScreen> createState() => _WineListScreenState();
}

class _WineListScreenState extends State<WineListScreen> {
  String _sortBy = 'none'; // 'none', 'name', 'year'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late final Key _listKey = ValueKey('reorderable_wines_${widget.category.name}');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wineProvider = Provider.of<WineProvider>(context);
    
    // get filtered wines
    List<Wine> filteredWines = widget.wines;
    if (_searchQuery.isNotEmpty) {
      filteredWines = widget.wines.where((wine) {
        final query = _searchQuery.toLowerCase();
        return wine.name.toLowerCase().contains(query) ||
            wine.producer.toLowerCase().contains(query) ||
            wine.region.toLowerCase().contains(query) ||
            wine.year.toLowerCase().contains(query);
      }).toList();
    }
    
    // get sorted wines
    List<Wine> displayWines = List.from(filteredWines);
    if (_sortBy == 'name') {
      displayWines.sort((a, b) => a.displayName.compareTo(b.displayName));
    } else if (_sortBy == 'year') {
      displayWines.sort((a, b) {
        final yearA = int.tryParse(a.year) ?? 0;
        final yearB = int.tryParse(b.year) ?? 0;
        return yearB.compareTo(yearA); // descending (newest first)
      });
    }

    Widget body;
    if (displayWines.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wine_bar_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noWinesInCategory,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      body = ReorderableListView.builder(
        key: _listKey,
        padding: const EdgeInsets.all(8),
        itemCount: displayWines.length,
        onReorder: (oldIndex, newIndex) {
          final wineIds = displayWines.map((w) => w.id).toList();
          wineProvider.reorderWinesInCategory(widget.category, wineIds, oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final wine = displayWines[index];
          return Card(
            key: ValueKey('${widget.category.name}_${wine.id}'),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: _buildLeading(context, wine),
              title: Row(
                children: [
                  // mark if wine is from "imported wines"
                  if (wine.fromImported == 'imported' && widget.category == WineCategory.meineWeine)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.import_export,
                            size: 22,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.imported,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Text(
                      wine.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              subtitle: Text(wine.producer.isNotEmpty ? wine.producer : '-'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/documents_icon.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.description, size: 24);
                      },
                    ),
                    tooltip: l10n.showDescriptions,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WineDescriptionsScreen(wineId: wine.id),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      wine.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: wine.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      wineProvider.toggleFavorite(wine.id);
                    },
                    tooltip: wine.isFavorite
                        ? l10n.removeFromFavorites
                        : l10n.addToFavorites,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _showDeleteConfirmation(context, wine, wineProvider, l10n),
                    tooltip: l10n.deleteWine,
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WineDetailScreen(wineId: wine.id),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Row(
            children: [
              Expanded(child: Text(widget.title)),
            ],
          ),
        actions: [
          if (widget.category == WineCategory.meineWeine)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.refresh,
              onPressed: () async {
                await wineProvider.refreshHistory();
                if (mounted) {
                  SnackbarMessages.show(context, l10n.winesUpdated);
                }
              },
            ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'none',
                child: Text(l10n.sortByNone),
              ),
              PopupMenuItem<String>(
                value: 'name',
                child: Text(l10n.sortByName),
              ),
              PopupMenuItem<String>(
                value: 'year',
                child: Text(l10n.sortByYear),
              ),
            ],
          ),
        ],
      ),
      body: body,
      floatingActionButton: (widget.category == WineCategory.meineWeine ||
              widget.category == WineCategory.importierteBeschreibungen)
          ? FloatingActionButton(
              heroTag: 'fab_${widget.category.name}',
              onPressed: () async {
                if (widget.category == WineCategory.importierteBeschreibungen) {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json'],
                    withData: true,
                  );
                  
                  if (result != null && result.files.single.bytes != null) {
                    try {
                      final jsonString = utf8.decode(result.files.single.bytes!);
                      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
                      final wine = Wine.fromJson(jsonData);
                      final importedWine = wine.copyWith(
                        category: WineCategory.importierteBeschreibungen,
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                      );
                      wineProvider.addWine(importedWine);
                      if (mounted) {
                        SnackbarMessages.show(context, '${l10n.wineImported}: ${wine.displayName}');
                      }
                    } catch (e) {
                      if (mounted) {
                        SnackbarMessages.show(context, '${l10n.importFailed}: $e');
                      }
                    }
                  }
                } else {
                  final result = await showDialog<Wine>(
                    context: context,
                    builder: (context) => AddWineDialog(category: widget.category),
                  );
                  if (result != null && mounted) {
                    wineProvider.addWine(result);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WineDescriptionsScreen(wineId: result.id),
                      ),
                    );
                  }
                }
              },
              tooltip: widget.category == WineCategory.meineWeine
                  ? l10n.addWine
                  : l10n.importWine,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildLeading(BuildContext context, Wine wine) {
    if (wine.imageUrl != null && wine.imageUrl!.isNotEmpty) {
      try {
        final imageData = wine.imageUrl!.split(',').last;
        return ClipOval(
          child: Image.memory(
            base64Decode(imageData),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(context, wine);
            },
          ),
        );
      } catch (e) {
        return _buildDefaultAvatar(context, wine);
      }
    }
    return _buildDefaultAvatar(context, wine);
  }

  Widget _buildDefaultAvatar(BuildContext context, Wine wine) {
    Color? backgroundColor;
    if (wine.category == WineCategory.importierteBeschreibungen && 
        wine.colorHex != null && wine.colorHex!.isNotEmpty) {
      backgroundColor = _getColorFromHex(wine.colorHex);
    }
    
    return CircleAvatar(
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      radius: 24,
      child: wine.name.isNotEmpty
          ? Text(
              wine.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )
          : const Icon(Icons.wine_bar, color: Colors.white),
    );
  }

  Color? _getColorFromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    final hexCode = hexString.replaceAll('#', '');
    try {
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return null;
    }
  }

  void _showDeleteConfirmation(BuildContext context, Wine wine, WineProvider wineProvider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.deleteWine),
          content: Text(l10n.deleteWineConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                if (wine.category == WineCategory.meineWeine) {
                  try {
                    await wineProvider.deleteWineFromBackend(wine.id);
                    if (mounted) {
                      SnackbarMessages.show(context, '${wine.displayName} ${l10n.wineDeleted}');
                    }
                  } catch (e) {
                    wineProvider.removeWine(wine.id);
                    if (mounted) {
                      SnackbarMessages.show(context, '${l10n.deleteFailed}: $e');
                    }
                  }
                } else {
                  wineProvider.removeWine(wine.id);
                  if (mounted) {
                    SnackbarMessages.show(context, '${wine.displayName} ${l10n.wineDeleted}');
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );
  }
}
