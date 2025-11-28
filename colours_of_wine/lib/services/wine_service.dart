/* service layer for HTTP-calls*/

import 'dart:convert';
import 'dart:typed_data';
import 'package:colours_of_wine/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class WineService {
  final String baseURL;
  final Future<String> Function() getToken;

  WineService({
    required this.baseURL,
    required this.getToken,
  });


  // get wine descriptions
  Future<List<Map<String, String>>> fetchDescriptions(WineData wineData) async {
    final token = await getToken();
    final query = wineData.toUriComponent();
    final wineName = wineData.name;
    final url = Uri.parse("$baseURL/fetchDescriptions").replace(
      queryParameters: {
        'token': token,
        'q': query,
        'name': wineName,
      },
    );
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
  }


  // generate summary 
  Future<Map<String, dynamic>> generateSummary(WineData wineData) async {
    final token = await getToken();
    final query = wineData.toUriComponent();
    final url = Uri.parse("$baseURL/generateSummary").replace(
      queryParameters: {
        "token": token,
        "q": query,
      },
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch summary (${response.statusCode})");
    }
    return jsonDecode(response.body);
  }


  // analyze label pics
  Future<WineData> analyzeLabel(Uint8List frontBytes, Uint8List backBytes,) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseURL/callGemini"),
    );

    request.fields['token'] = token;
    request.files.add(http.MultipartFile.fromBytes(
      'front',
      frontBytes,
      contentType: MediaType.parse('image/jpeg'),
      filename: 'front.jpeg',
    ));
    request.files.add(http.MultipartFile.fromBytes(
      'back',
      backBytes,
      contentType: MediaType.parse('image/jpeg'),
      filename: 'back.jpeg',
    ));

    try {
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception("Failed to call Gemini (${response.statusCode})");
      }
      final text = await response.stream.bytesToString();
      final decoded = jsonDecode(text);

      return WineData(Map<String, String>.from(decoded));
    } catch (e) {
      throw Exception("Gemini Analysis failed: $e");
    }
  }


  // get wine history from database
  Future<List<StoredWine>> getSearchHistory() async {
    final token = await getToken();
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
  }


  // delete stored wine entry from database
  Future<void> deleteSearch(String id) async {
    final token = await getToken();
    final url = Uri.parse("$baseURL/deleteSearch").replace(
      queryParameters: {
        'token': token,
        'id': id,
      },
    );

    final response = await http.post(url);
    if (response.statusCode != 200) {
      throw Exception("Error: Delete failed: ${response.statusCode}");
    }
  }
}