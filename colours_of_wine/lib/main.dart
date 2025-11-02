import 'dart:typed_data';
import 'dart:convert';                                              // convert JSON-Objects
import 'dart:io';
import 'package:flutter/material.dart';                             // widgets, buttons, ...
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';    // google gemini sdk
import 'package:url_launcher/url_launcher.dart';                    // for web search
import 'package:http/http.dart' as http;


// runs app
void main() {
  runApp(const WineApp());
}


/// root widget (stateless)
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


/// startscreen
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
          // Retaking
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);         // closes window and reopens camera
              _takePhotos();
            },
            child: const Text("Retake Photos"),
          ),
          // Confirming --> extract data
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


  // Extract data with gemini -->

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
    const apiKey = "AIzaSyC_u49bnxvaObp-2vVXSc0TvSLgQWqyT7c";                   // Gemini Api key
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);   // Gemini model
    
    // prompt -->
    final prompt = """                                                          
Du bist Experte für Weine und ihre Etiketten.
Analysiere die folgenden Weinetiketten (VORDER- UND RÜCKSEITE) gründlich.
Extrahiere und gebe die gesuchten Informationen im folgenden JSON-FORMAT zurück:
{
  "Name": "",
  "Winery": "",
  "Vintage": "",
  "Grape Variety": "",
  "Vineyard Location": "",
  "Country": ""
}

Wenn eine Information NICHT angegeben ist, lasse das Feld LEER!
""";

    final content = [                                // assemble prompt
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', frontBytes),
        DataPart('image/jpeg', backBytes),
      ])
    ];

    try {
      final response = await model.generateContent(content);   // let gemini answer
      if (response.text == null || response.text!.isEmpty) {
        throw Exception("No response from Gemini recieved.");
      }

      final jsonStart = response.text!.indexOf("{");           // extract JSON-Object
      final jsonEnd = response.text!.lastIndexOf("}") + 1;
      final jsonString = response.text!.substring(jsonStart, jsonEnd);

      final decoded = jsonDecode(jsonString);                 // convert JSON-object to map
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


// Web resarch -->
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
    final url = Uri.parse("http://66.135.20.195/wine-api?key=OlorHsQgpq9je6WIxeXIVY9Xdw&q=$query");

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
      const SnackBar(content: Text("Error retrieving wine descriptions.")),
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
        shape: RoundedRectangleBorder(                   // corners of window
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