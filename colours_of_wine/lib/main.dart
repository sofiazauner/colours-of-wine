import 'dart:typed_data';
import 'dart:convert';                                              // convert JSON-Objects
import 'dart:io';
import 'package:flutter/material.dart';                             // widgets, buttons, ...
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';    // google gemini sdk
import 'package:url_launcher/url_launcher.dart';                    // for web search
import 'package:http_parser/src/media_type.dart';                   // boilerplate for multipart
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';                           // for kIsWeb

// URL for our cloud functions.
// Uncomment the second for testing, first for production.
// (TODO: add a more convenient switch somehow)
final baseURL = "https://us-central1-colours-of-wine.cloudfunctions.net";
//final baseURL = "http://localhost:5001/colours-of-wine/us-central1";

// runs app
void main() {
  runApp(const WineApp());
}


// root widget (stateless)
class WineApp extends StatelessWidget {
  const WineApp({super.key});                                // for widget identification

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colours of Wine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromRGBO(237, 237, 213, 1),                   // background colour
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(225, 237, 237, 213)),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(),  // textfont
      ),
      home: const WineScannerPage(),                          // start screen
    );
  }
}


// startscreen
class WineScannerPage extends StatefulWidget {
  const WineScannerPage({super.key});

  @override
  State<WineScannerPage> createState() => _WineScannerPageState();
}


// layout of startcreen
class _WineScannerPageState extends State<WineScannerPage> {
  final ImagePicker _picker = ImagePicker();                 // camera
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  Map<String, String>? _wineData;                            // results of LLM-analysis
  bool _isLoading = false;                                   // for showing loading symbol


  // take two pictures with camera
  Future<void> _takePhotos() async {
    if (kIsWeb) {                                           // in Chrome upload images
    _showUploadDialog();
  } else {                                                  // handy takes pictures
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


  // check if user is satisfied with pics
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

    setState(() => _isLoading = true);                       // show loading symbol

    try {
      final result = await _callGemini(_frontBytes!, _backBytes!);  // give pics to gemini
      setState(() {
        _wineData = result;                                  // results in map<attribute, data>
      });
    } catch (e) {
      debugPrint("Error with analysis: $e");
      ScaffoldMessenger.of(context).showSnackBar(           // error message if needed
        const SnackBar(content: Text("Something went wrong while analyzing your wine label - Please try again!"), behavior: SnackBarBehavior.floating,  duration: const Duration(seconds: 7), backgroundColor: Color.fromARGB(255, 210, 8, 8), margin: const EdgeInsets.all(50),),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<Map<String, String>> _callGemini(Uint8List frontBytes, Uint8List backBytes) async {
    var request = new http.MultipartRequest('POST', Uri.parse("$baseURL/callGemini"));
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
      return Map<String, String>.from(decoded);
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
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText:
                        entry.key[0].toUpperCase() + entry.key.substring(1),
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
                _wineData = data;
              });
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}


// web resarch -->
Future<List<Map<String, String>>> _fetchWineDescription() async {
  if (_wineData == null || _isLoading) return [];       // check if data is available

  setState(() => _isLoading = true);                 // show loading screen

  try {
    final name = _wineData!['Name'] ?? '';
    final weingut = _wineData!['Winery'] ?? '';
    final jahrgang = _wineData!['Vintage'] ?? '';
    final rebsorte = _wineData!['Grape Variety'] ?? '';
    final anbaugebiet = _wineData!['Vineyard Location'] ?? '';
    final land = _wineData!['Country'] ?? '';
    
    final query = Uri.encodeComponent("$name $weingut $jahrgang $rebsorte $anbaugebiet $land description");

    // TODO should migrate this to AWS or something...
    final url = Uri.parse("$baseURL/searchWine?key=OlorHsQgpq9je6WIxeXIVY9Xdw&q=$query");

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


  // UI 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading                  // depending on state = loading-symbol, results, or startscreen
              ? const CircularProgressIndicator()
              : _wineData != null
                  ? _buildResultView()
                  : _buildStartView(),
        ),
      ),
    );
  }


  // regular startscreen
  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/logo.png', height: 230, fit: BoxFit.contain,),   // logo
        const SizedBox(height: 20),
        Text("Discover you wine",style: Theme.of(context).textTheme.titleLarge,), // text
        const SizedBox(height: 30),
        ElevatedButton.icon(                                   // cam 
          icon: const Icon(Icons.photo_camera),
          label: const Text("Scan label"),
          onPressed: _takePhotos,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Fill data in manually"),            // fill in manually
          onPressed: _enterManually,
        ),
      ],
    );
  }


  Widget _buildResultView() {                    // show registered data              
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 35),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(                                    // heading
          "Registered Information:",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.normal,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
        ),
        const SizedBox(height: 20),

        // entries
        ..._wineData!.entries.map(
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

      const SizedBox(height: 20),

      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(                                 // start web serach
              icon: const Icon(Icons.search),
              label: const Text("Get Wine Descriptions"),
              onPressed: () async {
                final results = await _fetchWineDescription();
                if (context.mounted) {
                  _showDescriptionPopup(results);
                }
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


void _showDescriptionPopup(List<Map<String, String>> results) {     // show result of web search
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(                   
          borderRadius: BorderRadius.circular(16),             
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(                                                  // header
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Wine Descriptions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),                  // close descriptions
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),


              const SizedBox(height: 10),

              Expanded(                                             // description (scrollable)
                child: results.isEmpty
                    ? const Center(
                        child: Text("No descriptions found."),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (item['url'] != null) ...[
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => launchUrl(Uri.parse(item['url']!)),
                                    child: Text(
                                      item['url']!,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
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
}

}


// flutter devices
// flutter run -d BQLDU19C04000620
