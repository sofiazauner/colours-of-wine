/* central controller: orchestrates the app (when to show which view) */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/foundation.dart';                 // for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';        // for authentication (Google Sign-In)
import 'package:intl/intl.dart';                          // for date formatting
import 'package:colours_of_wine/models/models.dart';
import 'package:colours_of_wine/models/validation.dart';
import 'package:colours_of_wine/config/config.dart';
import 'package:colours_of_wine/services/wine_repository.dart';
import 'package:colours_of_wine/utils/snackbar_messages.dart';
import 'package:colours_of_wine/utils/app_constants.dart';
import 'package:colours_of_wine/services/description_cache.dart';
import 'package:another_flushbar/flushbar.dart';

part '../views/wine_start_view.dart';
part '../views/wine_history_view.dart';
part '../views/wine_result_view.dart';
part '../views/wine_descriptions_view.dart';
part 'winedata_registration_camera.dart';
part 'winedata_registration_manual.dart';
part 'descriptions.dart';
part 'summary.dart';
part 'previous_searches.dart';
part '../views/setting_view.dart';

// Which dataset the user wants to browse in the app.
// "mine" = personal wines (default)
// "others" = other/public wines (if supported by backend)
enum WineCollectionScope { mine, others }

// startscreen
class WineScannerPage extends StatefulWidget {
  const WineScannerPage(this._user, {super.key});
  final User _user;

  @override
  State<WineScannerPage> createState() => _WineScannerPageState(_user);
}

// layout of startcreen
class _WineScannerPageState extends State<WineScannerPage> {
  _WineScannerPageState(this._user);

  late final WineRepository _wineRepository;    // service layer "talking-point"
  final ImagePicker _picker = ImagePicker();
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  WineData? _wineData;                    // results of LLM-analysis of Label
  List<StoredWine>? _pastWineData;        // previous search results
  bool _isLoading = false;
  final User _user;                       // user ID
  String? _token;
  WineWebResult? _webResult;              // descriptions found in web
  final TextEditingController _searchController = TextEditingController();      // for searching previous winesearches in history view
  String _searchQuery = '';
  List<Map<String, String>> _selectedDescriptionsForSummary = [];               // for summary generation
  int defaultDescriptionCount = AppConstants.defaultSelectedDescriptionsCount;  // default

  // User-selected scope (shown via popup on first render).
  WineCollectionScope _collectionScope = WineCollectionScope.mine;
  bool _hasShownScopeDialog = false;

  @override
  void initState() {
    super.initState();

    _wineRepository = WineRepository(
      baseURL: baseURL,                   // from config.dart
      getToken: _getToken,
    );

    // Show scope selector once when the page is first displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCollectionScopeDialogIfNeeded();
    });
  }

  Future<void> _showCollectionScopeDialogIfNeeded() async {
    if (!mounted || _hasShownScopeDialog) return;
    _hasShownScopeDialog = true;
    await _showCollectionScopeDialog(force: true);
  }

  Future<void> _showCollectionScopeDialog({required bool force}) async {
    if (!mounted) return;

    WineCollectionScope tempScope = _collectionScope;

    await showDialog<void>(
      context: context,
      barrierDismissible: !force,
      builder: (context) {
        return AlertDialog(
          title: const Text('Weinauswahl'),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<WineCollectionScope>(
                    title: const Text('Eigene Weine'),
                    subtitle: const Text('Deine persönlichen Suchergebnisse'),
                    value: WineCollectionScope.mine,
                    groupValue: tempScope,
                    onChanged: (v) => setLocalState(() => tempScope = v!),
                  ),
                  RadioListTile<WineCollectionScope>(
                    title: const Text('Andere Weine'),
                    subtitle:
                    const Text('Öffentliche/andere Einträge (falls verfügbar)'),
                    value: WineCollectionScope.others,
                    groupValue: tempScope,
                    onChanged: (v) => setLocalState(() => tempScope = v!),
                  ),
                ],
              );
            },
          ),
          actions: [
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
            ElevatedButton(
              onPressed: () {
                // Closing the dialog is always safe (the dialog context is still valid),
                // but setState must only be called if the State is still mounted.
                if (mounted) {
                  setState(() {
                    _collectionScope = tempScope;

                    // If the history view is currently open, refresh it the next time it is shown.
                    _pastWineData = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                }

                Navigator.of(context).pop();
              },
              child: const Text('Weiter'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    _token ??= await _user.getIdToken();
    return _token!;
  }

  // signing out
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // clear data
      DescriptionCache.clear();
      setState(() {
        _wineData = null;
        _pastWineData = null;
        _frontBytes = null;
        _backBytes = null;
        _token = null;
        _webResult = null;
      });
    } catch (e) {
      debugPrint("Sign-out error: $e");
      SnackbarMessages.showErrorBar(context, SnackbarMessages.signout);
    }
  }

  // shows user interfaces for the different screens --->
  @override
  Widget build(BuildContext context) {
    final email = _user.email;
    final userLabel = email ?? "Unknown user";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.userEmailColour,
        actions: [
          Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 6, right: 2),
            child: TextButton(
              onPressed: () => _showCollectionScopeDialog(force: false),
              child: Text(
                _collectionScope == WineCollectionScope.mine
                    ? 'Eigene Weine'
                    : 'Andere Weine',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 0, left: 0, bottom: 30),
            child: Center(
              child: Text(
                userLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          IconButton(
            padding: const EdgeInsets.only(right:2, bottom: 30),
            iconSize: 18,
            icon: const Icon(Icons.logout),
            constraints: const BoxConstraints(minWidth: 35, minHeight: 30),
            tooltip: AppConstants.signOutButton,
            onPressed: _signOut,
          ),
          IconButton(
            padding: const EdgeInsets.only(bottom: 30),
            iconSize: 18,
            icon: const Icon(Icons.settings),
            constraints: const BoxConstraints(minWidth: 15, minHeight: 30),
            tooltip: AppConstants.settingsButton,
            onPressed: showSettingPopup,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading // depending on state = loading-symbol, results, login,...
              ? const CircularProgressIndicator()
              : _wineData != null
                  ? _buildResultView()
                  : _pastWineData != null
                      ? _buildHistoryView()
                      : _buildStartView(),
        ),
      ),
    );
  }
}
