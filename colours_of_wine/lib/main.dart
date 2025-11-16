import 'dart:convert'; 
import 'dart:typed_data';                                                     // convert JSON-Objects
import 'dart:io';
import 'package:flutter/material.dart';                                       // widgets, buttons, ...
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';              // google gemini sdk
import 'package:url_launcher/url_launcher.dart';                              // for web search
import 'package:http_parser/src/media_type.dart';                             // boilerplate for multipart
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';                                     // for kIsWeb
import 'package:firebase_core/firebase_core.dart';                            // for firebase
import 'package:colours_of_wine/firebase_options.dart';                       
import 'package:firebase_auth/firebase_auth.dart';                            // for authentication (Google Sign-In)
import 'package:google_sign_in/google_sign_in.dart';                          
import 'package:intl/intl.dart';                                              // for date formatting


// URL for our cloud functions. Uncomment the second for testing, first for production.
final baseURL = "https://us-central1-colours-of-wine.cloudfunctions.net";
// final baseURL = "http://localhost:5001/colours-of-wine/us-central1";


// runs app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WineApp());
}

// root widget (stateless)
class WineApp extends StatelessWidget {
  const WineApp({super.key});                          // for widget identification

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colours of Wine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromRGBO(237, 237, 213, 1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(225, 237, 237, 213)),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(),
      ),
      home: const InitPage(),                          // start screen
    );
  }
}




// Login Logic -->

// init screen - decide if we need login or not
class InitPage extends StatefulWidget {
  const InitPage({super.key});

  @override
  State<InitPage> createState() => _InitPageState();
}

class _InitPageState extends State<InitPage> {
  // UI 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildInitView(),
        ),
      ),
    );
  }

  Widget _buildInitView() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasError) {
          return const Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }

        if (!snapshot.hasData) {
          // needs sign in
          return const LoginPage();
        }

        final user = snapshot.data!;
        return WineScannerPage(user);
      },
    );
  }
}

// login screen
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // UI 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildLoginView(),
        ),
      ),
    );
  }

  // login screen (Google Sign-In)
  Widget _buildLoginView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/logo.png', height: 230, fit: BoxFit.contain,),   // logo
        const SizedBox(height: 20),
        Text("Sign in to start", style: Theme.of(context).textTheme.titleLarge,),
        const SizedBox(height: 30),
        ElevatedButton.icon( 
          icon: const Icon(Icons.login),
          label: const Text("Sign in with Google"),
          onPressed: _signInWithGoogle,
        ),
      ],
    );
  }

  Future<Widget> _signInWithGoogle() async {
    final user = await _signInWithGoogleImpl();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to sign in"), behavior: SnackBarBehavior.floating,  duration: const Duration(seconds: 7), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: const EdgeInsets.all(50),),
      );
    }
    return InitPage();
  }

  Future<UserCredential?> _signInWithGoogleImpl() async {
    if (kIsWeb) {                                             
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser!.authentication;
      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    }
  }
}




// classes for Data-Structures-->

// class for storing wines
class StoredWine {
  final String id;
  final String name;
  final List<String> descriptions;
  final DateTime? createdAt;

  StoredWine({
    required this.id, 
    required this.name,
    required this.descriptions,
    this.createdAt,});

   factory StoredWine.fromJson(Map<String, dynamic> json) {
    final rawList = json['descriptions'];
    final List<String> descriptions = rawList is List
        ? rawList.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
        : [];
    return StoredWine(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      descriptions: descriptions,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
    );
  }
}

// web search result structure
class WineWebResult {
  final String summary;
  final bool approved;
  final Image image;

  WineWebResult(
    this.summary,
    this.approved,
    this.image
  );
}

// wine data structure
class WineData {
  WineData(Map<String, String> data) :
    name = data['Name'] ?? '',
    winery = data['Winery'] ?? '',
    vintage = data['Vintage'] ?? '',
    grapeVariety = data['Grape Variety'] ?? '',
    vineyardLocation = data['Vineyard Location'] ?? '',
    country = data['Country'] ?? '';

  Map<String, String> toMap() {
    return {
      'Name': name,
      'Winery': winery,
      'Vintage': vintage,
      'Grape Variety': grapeVariety,
      'Vineyard Location': vineyardLocation,
      'Country': country
    };
  }

  final String name;
  final String winery;           // Weingut
  final String vintage;          // Jahrgang
  final String grapeVariety;     // Rebsorte
  final String vineyardLocation; // Anbaugebiet
  final String country;

  final allowedDomains = [       // filter descriptions form Internet and only allow trusted wine sites for web search
      "winefolly.com",
      "decanter.com",
      "wineenthusiast.com",
      "wine.com",
      "vivino.com",
      "wine-searcher.com",
      "jancisrobinson.com",
      "vinous.com",
      "jamessuckling.com",
      "winespectator.com",
      "falstaff.de",
      "wein.plus",
      "cellartracker.com",
      "vicampo.de",
    ];

  // Encode the wine as a URI component.
  String toUriComponent() {
    final name = this.name;
    final weingut = this.winery;
    final jahrgang = this.vintage;
    final rebsorte = this.grapeVariety;
    final anbaugebiet = this.vineyardLocation;
    final land = this.country;

    final siteFilter = allowedDomains.map((d) => "site:$d").join(" OR ");
    
    return Uri.encodeComponent("$name $weingut $jahrgang $rebsorte $anbaugebiet $land wine description ($siteFilter)");
  }
}




// Central controller + UI -->

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

  final ImagePicker _picker = ImagePicker();                 // camera
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  WineData? _wineData;                                       // results of LLM-analysis of Label
  List<StoredWine>? _pastWineData;                           // previous results
  bool _isLoading = false;                                   
  final User _user;                                          // user ID
  String? _token;

  final TextEditingController _searchController = TextEditingController();  // for searching previous winesearches in history view
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    _token ??= await _user.getIdToken();
    return _token!;
  } 

  // Sign out 
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
      });

  } catch (e) {
    debugPrint("Sign-out error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Error while signing out - please try again!"),behavior: SnackBarBehavior.floating,duration: Duration(seconds: 5),backgroundColor: Color.fromARGB(255, 210, 8, 8),margin: EdgeInsets.all(50),
      ),
    );
  }
}




// Logic for wine data registration (camera, manual) -->

  // take pictures of labels with camera
  Future<void> _takePhotos() async {
    final token = await _getToken();
    if (kIsWeb) {                                           // in Chrome upload images
      _showUploadDialog();
    } else {                                                // handy takes pictures
      final front = await _picker.pickImage(source: ImageSource.camera);
      if (front == null) return;
      final back = await _picker.pickImage(source: ImageSource.camera);
      if (back == null) return;
      final Uint8List frontBytes = await front.readAsBytes();
      final Uint8List backBytes = await back.readAsBytes();

      setState(() {
        _frontBytes = frontBytes;
        _backBytes = backBytes;
      });

      _showConfirmationDialog();
    }
  }

  // upload labels in chrome
  void _showUploadDialog() {
    Uint8List? frontBytes;
    Uint8List? backBytes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Upload Photos of Label",
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(                                  // front label
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text("Front Label"),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final front = await _picker.pickImage(source: ImageSource.gallery);
                      if (front == null) return;
                      final bytes = await front.readAsBytes();
                      setDialogState(() => frontBytes = bytes);
                    },
                  ),

                  if (frontBytes != null) ...[
                    const SizedBox(height: 6),
                    const Text("✅ Front Label", style: TextStyle(color: Colors.green)),
                  ],

                  const SizedBox(height: 16),

                  // Back label upload
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text("Upload Back Label"),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final back = await _picker.pickImage(source: ImageSource.gallery);
                      if (back == null) return;
                      final bytes = await back.readAsBytes();
                      setDialogState(() => backBytes = bytes);
                    },
                  ),

                  if (backBytes != null) ...[
                    const SizedBox(height: 6),
                    const Text("✅ Back Label", style: TextStyle(color: Colors.green)),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (frontBytes == null || backBytes == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please upload both label photos!"), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 6), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: EdgeInsets.all(50),),
                      );
                      return;
                    }

                    Navigator.pop(context);
                    setState(() {
                      _frontBytes = frontBytes;
                      _backBytes = backBytes;
                    });
                    _showConfirmationDialog();
                  },
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // check if user is satisfied with pics (uploaded or taken)
  void _showConfirmationDialog() {
    showDialog(
      context: context,                                   // open on top of screen
      builder: (_) => AlertDialog(
        title: const Text("Confirm Photos"),
        content: Column(
          mainAxisSize: MainAxisSize.min,                 // window just as big as needed
          children: [
            if (_frontBytes != null)...[
              const Text("Front Label:", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16,),),
              Image.memory(_frontBytes!, height: 150, fit: BoxFit.cover),
              const SizedBox(height: 10),],

            if (_backBytes != null)...[
              const Text("Back Label:", style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16,),),
              Image.memory(_backBytes!, height: 150, fit: BoxFit.cover),
            ]
          ],
        ),
        actions: [
          // retaking
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);         // closes window and reopens camera
              _takePhotos();
            },
            child: const Text("Retake Photos"),
          ),
          // confirming --> extract data
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);         // closes window and starts LLM-analyzing
              _analyzeImages();
            },
            child: const Text("Analyze Label"),
          ),
        ],
      ),
    );
  }

  // extract data with gemini -->
  Future<void> _analyzeImages() async {
    if (_frontBytes == null || _backBytes == null) return;   // works only with both pictures 
    if (_isLoading) return;                                  // no double requests

    setState(() => _isLoading = true);                       

    try {
      final result = await _callGemini(_frontBytes!, _backBytes!);  // give pics to gemini
      setState(() {
        _wineData = result;                                  // results in map<attribute, data>
      });
    } catch (e) {
      debugPrint("Error with analysis: $e");
      ScaffoldMessenger.of(context).showSnackBar(           
        const SnackBar(content: Text("Something went wrong while analyzing your wine label - Please try again!"), behavior: SnackBarBehavior.floating,  duration: const Duration(seconds: 7), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: const EdgeInsets.all(50),),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<WineData> _callGemini(Uint8List frontBytes, Uint8List backBytes) async {
    var request = new http.MultipartRequest('POST', Uri.parse("$baseURL/callGemini"));
    final token = await _getToken();
    request.fields['token'] = token;
    request.files.add(http.MultipartFile.fromBytes('front', frontBytes,
      contentType: MediaType.parse('image/jpeg'), filename: 'front.jpeg'));
    request.files.add(http.MultipartFile.fromBytes('back', backBytes,
      contentType: MediaType.parse('image/jpeg'), filename: 'back.jpeg'));

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception("Failed to call Gemini (${response.statusCode})");
      }

      final text = await response.stream.bytesToString();
      final decoded = jsonDecode(text);
      return WineData(Map<String, String>.from(decoded));
    } catch (e) {
      debugPrint("Gemini Error: $e");
      throw Exception("Gemini Analysis failed: $e");
    }
  }

  // for filling in data manually -->
  Future<void> _enterManually() async {
    final Map<String, TextEditingController> controllers = {
      "Name": TextEditingController(),
      "Winery": TextEditingController(),
      "Vintage": TextEditingController(),
      "Grape Variety": TextEditingController(),
      "Vineyard Location": TextEditingController(),
      "Country": TextEditingController(),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter wine details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries.map((entry) {
                 String label;
                  if (entry.key == "Grape Variety") {
                    label = "Grape Variety     (mandatory)";
                  } else { 
                    label = entry.key[0].toUpperCase() + entry.key.substring(1);
                  }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            ElevatedButton(                    // closes window        
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(                    // saves data
              onPressed: () {
                final data = <String, String>{};
                controllers.forEach((key, ctrl) {
                  data[key] = ctrl.text.trim();
                });

                Navigator.pop(context);
                setState(() {
                  _wineData = WineData(data);
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }




  // Logic for getting wine descriptions from the Internet -->

  // web resarch
  Future<List<Map<String, String>>> _fetchWineDescription() async {
    if (_wineData == null || _isLoading) return [];            // check if data is available
 
    if (_wineData!.grapeVariety.isEmpty) {                     // check if variety is given
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Grape Variety is mandatory! Please make sure it gets registered and try again!", style: TextStyle(color: Color.fromARGB(255, 255, 255, 251)), textAlign: TextAlign.center,),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 8),
        backgroundColor: Color.fromARGB(255, 184, 114, 17), 
        margin: const EdgeInsets.only(bottom: 500, left: 50, right: 50,),
      ),
    );
    return [];}

    setState(() => _isLoading = true);                   // show loading screen

    try {
      final query = _wineData!.toUriComponent();
      final token = await _getToken();
      final wineName = _wineData!.name;
      final url = Uri.parse("$baseURL/fetchDescriptions").replace(queryParameters: {
        'token': token,
        'q': query,
        'name': wineName,});
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Search failed with ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final results = <Map<String, String>>[];

      if (data['organic_results'] != null) {
        for (var item in data['organic_results']) {
          results.add({
            "title": item['title'] ?? "No title",
            "snippet": item['snippet'] ?? "",
            "url": item['link'] ?? "",
          });
        }
      }

      return results;

    } catch (e) {
      debugPrint("Fehler beim Laden der Beschreibung: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error retrieving wine descriptions - Please try again!"), behavior: SnackBarBehavior.floating,  duration: const Duration(seconds: 7), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: const EdgeInsets.all(50),),
      );
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  


// Logic to summarize descriptions --> -->

  // get summary from descriptions
  Future<Map<String, dynamic>> fetchSummary() async {
    if (_isLoading) {
      return {};
    }
    setState(() => _isLoading = true);  
    try {
      final token = await _getToken();
      final query = _wineData!.toUriComponent();
      final url = Uri.parse("$baseURL/generateSummary?token=$token&q=$query");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch summary (${response.statusCode})");
      }

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Error while fetching summary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error retrieving summary - Please try again!"), behavior: SnackBarBehavior.floating,  duration: const Duration(seconds: 7), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: const EdgeInsets.all(50),),
      );
      return {};
    } finally {
      setState(() => _isLoading = false);
    }
  }




// Logic for generating images with Gemini -->
//(TODO: !!)




// Logic for previous search database -->

  // find previous searches
  Future<List<StoredWine>> _fetchSearchHistory() async {
    if (_isLoading) return []; 

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      final url = Uri.parse("$baseURL/searchHistory?token=$token");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Search failed with ${response.statusCode}");
      }

      final List<dynamic> data = jsonDecode(response.body);
      final List<StoredWine> list = data.map((item) {
        final map = Map<String, dynamic>.from(item);
        return StoredWine.fromJson(map);
      }).toList();  

      return list;
    } catch (e) {
      debugPrint("Fehler beim Laden der Beschreibung: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error retrieving wine descriptions - Please try again!"), behavior: SnackBarBehavior.floating,  duration: const Duration(seconds: 7), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: const EdgeInsets.all(50),),
      );
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showSearchHistory() async {
    final history = await _fetchSearchHistory();
    setState(() {
      _pastWineData = history;
    });
  }
  
  //delete previous search entry
  Future<void> _deleteStoredWine(String id) async {
  try {
    final token = await _getToken();
    final url = Uri.parse("$baseURL/deleteSearch").replace(     // remove from database
      queryParameters: {
        'token': token,
        'id': id,
      },
    );

    final response = await http.post(url);

    if (response.statusCode != 200) {
      throw Exception("Error: Delete failed: ${response.statusCode}");
    }

    setState(() {
      _pastWineData!.removeWhere((w) => w.id == id);           // remove from local list
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Entry was successfully deleted!", style: TextStyle(color: Color.fromARGB(255, 255, 255, 251)), textAlign: TextAlign.center,),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        backgroundColor: Color.fromARGB(255, 184, 114, 17), 
        margin: const EdgeInsets.only(bottom: 500, left: 50, right: 50,),
      ),
    );

  } catch (e) {
    debugPrint("Delete error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Failed to delete entry - Please try again!"),behavior: SnackBarBehavior.floating,duration: Duration(seconds: 4),backgroundColor: Colors.red,),
    );
  }
}




// User Interfaces for the different screens --->

  @override
  Widget build(BuildContext context) {
    final email = _user.email;
    final userLabel = email ?? "Unknown user";

    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 0),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 0, left: 0, bottom: 30),
          child: Center(
            child: Text(
              userLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        IconButton(
          padding: const EdgeInsets.only(bottom: 30),
          iconSize: 18,
          tooltip: "Sign out",
          icon: const Icon(Icons.logout),
          onPressed: _signOut,
        ),
      ],
    ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading                  // depending on state = loading-symbol, results, login,...
              ? const CircularProgressIndicator()
              : _wineData != null
                  ? _buildResultView()
                  : _pastWineData != null ?
                    _buildHistoryView() :
                    _buildStartView(),
        ),
      ),
    );
  }

  // regular homescreen
  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/logo.png', height: 230, fit: BoxFit.contain,),   // logo
        const SizedBox(height: 20),
        Text("Discover you wine",style: Theme.of(context).textTheme.titleLarge,), 
        const SizedBox(height: 30),
        ElevatedButton.icon(                                   // cam 
          icon: const Icon(Icons.photo_camera),
          label: const Text("Scan label"),
          onPressed: _takePhotos,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Fill data in manually"),
          onPressed: _enterManually,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text("Previous searches"),
          onPressed: _showSearchHistory,
        ),
      ],
    );
  }

  // generic wine card for displaying wine data
  Widget _buildWineCard(WineData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...data.toMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        "${e.key[0].toUpperCase()}${e.key.substring(1)}:",    // categories
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5), 
                    Expanded(
                      child: Text(                                            // entries
                        e.value.isEmpty ? "-" : e.value,                      // if nothing found "-"
                        style: const TextStyle(
                          fontSize: 16,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // wine card for previous searches
  Widget _buildStoredWineCard(StoredWine item) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Stack(
      children: [
        Positioned(
          right: 6,
          top: 6,
          child: InkWell(
            onTap: () => _deleteStoredWine(item.id),
            child: const Icon(Icons.close, size: 20, color: Color.fromARGB(255, 111, 101, 25)),
          ),
        ),
    
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name.isEmpty ? "(No name)" : item.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 113, 9, 9),
            ),
          ),

          const SizedBox(height: 8),

          // Optional: Datum
          if (item.createdAt != null) ...[
            Text(
              DateFormat.yMMMMd().add_jm().format(item.createdAt!.toLocal()),
              style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 71, 69, 69)),
            ),
            const SizedBox(height: 8),
          ],

          // Feld mit Beschreibungen
          if (item.descriptions.isNotEmpty) ...[
            const Text(
              "Descriptions:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...item.descriptions.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    "• $d",
                    style: const TextStyle(fontSize: 14),
                  ),
                )),
          ] else
            const Text(
              "No descriptions saved.",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    ),
    ],
    ),
  );
}

  // previous searches view
  Widget _buildHistoryView() {
    // filter for searching option
    final List<StoredWine> visibleItems = _pastWineData!.where((w) =>_searchQuery.isEmpty || w.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Text(                                    // heading
              "Previous Searches:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.normal,
                color: Color.fromARGB(255, 113, 9, 9),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(                                               // search bar
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: "Search for a wine name",
                    border: OutlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 236, 111, 111))),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    prefixIcon: Icon(Icons.wine_bar),
                    prefixIconColor: Color.fromARGB(255, 113, 9, 9),
                    fillColor: Color.fromARGB(255, 249, 246, 233),
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _searchQuery = value.trim();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: "Search",
                onPressed: () {
                  setState(() {
                    _searchQuery = _searchController.text.trim();
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (visibleItems.isEmpty)     // no matches
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "No entries found.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
         )
        else                          // show matches
          ...visibleItems.map((e) => Column(
                children: [
                  _buildStoredWineCard(e),
                  const SizedBox(height: 1),
                ],
              )),

          const SizedBox(height: 1),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Search"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 7),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Close"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _pastWineData = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // result view after analyzing label to show registered data
  Widget _buildResultView() {                    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Text(                                    // heading
              "Registered Information:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.normal,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // entries
          _buildWineCard(_wineData!),

          const SizedBox(height: 20),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(                                 // start web search
                  icon: const Icon(Icons.search),
                  label: const Text("Get Wine Descriptions"),
                  onPressed: () async {
                    final result = await _fetchWineDescription();
                     if (result.isEmpty) return;
                     if (!mounted) return;

                      _showDescriptionPopup(result);
                  },
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try again"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    setState(() {
                      _wineData = null;
                      _frontBytes = null;
                      _backBytes = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // view for descriptions from web search
    void _showDescriptionPopup(List<Map<String, String>> results) {
    showDialog(
      context: context,
      builder: (context) {
        bool isSummaryLoading = false;
        WineWebResult? webResult = null;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Wine Descriptions   ||",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 19),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size(180, 28),
                              ),
                              icon:
                                  const Icon(Icons.edit_document, size: 18),
                              label: const Text("Generate Summary"),
                              onPressed: isSummaryLoading
                                  ? null
                                  : () async {
                                      setStateDialog(() {
                                        isSummaryLoading = true;
                                      });

                                      try {
                                        final result = await fetchSummary();
                                        setStateDialog(() {
                                          final summary = result["summary"] as String;
                                          final approved = result["approved"] as bool;
                                          final imageString = result["image"] as String;
                                          final image = Image.memory(base64Decode(imageString));
                                          webResult = WineWebResult(summary!, approved!, image);
                                        });
                                      } catch (e) {
                                        debugPrint(
                                            "Error fetching summary: $e");
                                      } finally {
                                        setStateDialog(() {
                                          isSummaryLoading = false;
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (isSummaryLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    if (webResult != null) ...[
                      webResult!.image,
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            webResult!.approved
                                ? Icons.check_circle
                                : Icons.error,
                            size: 18,
                            color: webResult!.approved
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            webResult!.approved
                                ? "AI Summary:"
                                : "There was an issue with the summary - Please try Again!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: webResult!.approved
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        webResult!.summary,
                        style: const TextStyle(fontSize: 14),
                      ),

                      const Divider(height: 24),
                    ],

                    // Normal descriptions list
                    Expanded(
                      child: results.isEmpty
                          ? const Center(
                              child: Text("No descriptions found."),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final item = results[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? "Untitled",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['snippet'] ?? "",
                                        style:
                                            const TextStyle(fontSize: 14),
                                      ),
                                      if (item['url'] != null) ...[
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => launchUrl(
                                            Uri.parse(item['url']!),
                                          ),
                                          child: Text(
                                            item['url']!,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Divider(height: 20),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}



// flutter devices
// flutter run -d BQLDU19C04000620
