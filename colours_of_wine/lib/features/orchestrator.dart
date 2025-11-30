/* central controller: orchestrates the app (when to show which view) */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:flutter/foundation.dart';                 // for kIsWeb
import 'package:firebase_auth/firebase_auth.dart';        // for authentication (Google Sign-In)
import 'package:intl/intl.dart';                          // for date formatting
import 'package:colours_of_wine/models/models.dart';
import 'package:colours_of_wine/models/validation.dart';
import 'package:colours_of_wine/config/config.dart';
import 'package:colours_of_wine/services/wine_service.dart';
import 'package:colours_of_wine/utils/snackbar_messages.dart';
import 'package:colours_of_wine/utils/app_constants.dart';

part '../views/wine_start_view.dart';
part '../views/wine_history_view.dart';
part '../views/wine_result_view.dart';
part '../views/wine_descriptions_view.dart';
part 'winedata_registration_camera.dart';
part 'winedata_registration_manual.dart';
part 'descriptions.dart';
part 'summary.dart';
part 'previous_searches.dart';


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
  final TextEditingController _searchController = TextEditingController();  // for searching previous winesearches in history view
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _wineRepository = WineRepository(
      baseURL: baseURL,                   // from config.dart
      getToken: _getToken,
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
            padding: const EdgeInsets.only(bottom: 30),
            iconSize: 18,
            tooltip: AppConstants.signOutButton,
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
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
