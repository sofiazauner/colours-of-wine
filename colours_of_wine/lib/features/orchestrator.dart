/* central controller: orchestrates the app (when to show which view) */

library orchestrator;

import 'dart:convert';
import 'dart:typed_data';

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

enum StartSelection { ownWines, otherWines }

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

  String? _currentHistoryId; // for storing current search (Option A)

  WineWebResult? _webResult;              // descriptions found in web
  final TextEditingController _searchController = TextEditingController();      // for searching previous winesearches in history view
  String _searchQuery = '';

  List<Map<String, String>> _selectedDescriptionsForSummary = [];
  int defaultDescriptionCount = AppConstants.defaultSelectedDescriptionsCount;

  StartSelection? _startSelection;

  @override
  void initState() {
    super.initState();

    _wineRepository = WineRepository(
      baseURL: baseURL,                   // from config.dart
      getToken: _getToken,
    );

    // Show scope selector once when the page is first displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showStartSelectionDialog();
    });
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

  String _modeLabel(StartSelection sel) {
    switch (sel) {
      case StartSelection.ownWines:
        return "My wines";
      case StartSelection.otherWines:
        return "Other wines";
    }
  }

  Future<void> _setMode(StartSelection sel) async {
    if (!mounted) return;

    // reset view state when switching
    setState(() {
      _startSelection = sel;
      _wineData = null;
      _webResult = null;
      _frontBytes = null;
      _backBytes = null;
      _currentHistoryId = null;
      _selectedDescriptionsForSummary = [];
      _searchQuery = '';
      _searchController.clear();

      // if switching away from history, close history list
      if (sel == StartSelection.otherWines) {
        _pastWineData = null;
      }
    });

    // If "My wines" selected -> load history and show it
    if (sel == StartSelection.ownWines) {
      await _showSearchHistory();
    }
  }

  Future<void> _showModeSwitcherDialog() async {
    if (_startSelection == null) {
      await _showStartSelectionDialog();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text("Switch mode"),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _setMode(StartSelection.ownWines);
              },
              child: const Text("My wines"),
            ),
            SimpleDialogOption(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _setMode(StartSelection.otherWines);
              },
              child: const Text("Other wines"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStartSelectionDialog() async {
    if (_startSelection != null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Select Mode"),
          content: const Text("What do you want to view?"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _setMode(StartSelection.otherWines);
              },
              child: const Text("Other wines"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _setMode(StartSelection.ownWines);
              },
              child: const Text("My wines"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      DescriptionCache.clear();
      if (!mounted) return;

      setState(() {
        _wineData = null;
        _pastWineData = null;
        _frontBytes = null;
        _backBytes = null;
        _token = null;
        _webResult = null;
        _currentHistoryId = null;
        _startSelection = null;
        _searchQuery = '';
        _searchController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showStartSelectionDialog();
      });
    } catch (e) {
      debugPrint("Sign-out error: $e");
      SnackbarMessages.showErrorBar(context, SnackbarMessages.signout);
    }
  }

  Widget _buildModeButton() {
    final sel = _startSelection;
    final label = (sel == null) ? "Select mode" : _modeLabel(sel);

    return Padding(
      padding: const EdgeInsets.only(bottom: 30, right: 6),
      child: OutlinedButton(
        onPressed: _showModeSwitcherDialog,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user.email;
    final userLabel = email ?? "Unknown user";

    if (_startSelection == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.userEmailColour,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8, bottom: 30),
            child: Center(
              child: Text(
                userLabel,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),

          // NEW: mode button next to the user label
          _buildModeButton(),

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
