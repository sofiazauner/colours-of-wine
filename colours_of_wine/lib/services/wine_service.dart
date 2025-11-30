/* service layer for HTTP-calls*/

import 'dart:convert';
import 'dart:typed_data';
import 'package:colours_of_wine/models/models.dart';
import 'package:colours_of_wine/models/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class WineService {
  final String baseURL;
  final Future<String> Function() getToken;

  WineService({
    required this.baseURL,
    required this.getToken,
  });

  Future<T> retry<T>(Future<T> Function() fn, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: i));
      }
    }
    throw NetworkException("Max retries exceeded");
  }

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
      throw ApiException(response.statusCode, "Search failed");
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
      throw ApiException(response.statusCode, "Failed to fetch summary");
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

    final response = await request.send();
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Failed to call Gemini");
    }
    final text = await response.stream.bytesToString();
    final decoded = jsonDecode(text);

    return WineData(Map<String, String>.from(decoded));
  }


  // get wine history from database
  Future<List<StoredWine>> getSearchHistory() async {
    final token = await getToken();
    final url = Uri.parse("$baseURL/searchHistory?token=$token");
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Search failed");
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
      throw ApiException(response.statusCode, "Error: Delete failed");
    }
  }
}
