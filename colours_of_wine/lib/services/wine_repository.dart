/* service layer for HTTP-calls*/

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/src/response.dart';
import 'package:colours_of_wine/models/models.dart';
import 'package:colours_of_wine/models/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class WineRepository {
  final String baseURL;
  final Future<String> Function() getToken;

  WineRepository({
    required this.baseURL,
    required this.getToken,
  });

  Future<Response> get(String endpoint, {String? query, String? name}) async {
    final token = await getToken();
    final url = Uri.parse("$baseURL/$endpoint").replace(
      queryParameters: {
        'token': token,
        'q': query,
        'name': name,
      },
    );
    return await http.get(url).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw NetworkException('Request timed out');
      },
    );
  }

  Future<Response> post(String endpoint, String id) async {
    final token = await getToken();
    final url = Uri.parse("$baseURL/$endpoint").replace(
      queryParameters: {
        'token': token,
        'id': id,
      },
    );

    return await http.post(url).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw NetworkException('Request timed out');
      },
    );
  }

  Future<Response> postJson(String endpoint, {Map<String, dynamic>? body}) async {
  final token = await getToken();
  final url = Uri.parse("$baseURL/$endpoint").replace(
    queryParameters: {
      'token': token,
    },
  );

  return await http.post(url, headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body ?? {}),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw NetworkException('Request timed out');
      },
    );
  }

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

  /// Fetches the wine descriptions from Serp API.
  ///
  /// Takes a WineData received from the user.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<List<Map<String, String>>> fetchDescriptions(WineData wineData) async {
    final query = wineData.toUriComponent();
    final wineName = wineData.name;
    final response = await get("fetchDescriptions", query: query, name: wineName);
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
          "articleText": item['articleText'] ?? "",
        });
      }
    }
    return results;
  }


  /// Generates a wine summary using Gemini AI Agentic Reviewer Loop and selected descriptions.
  /// 
  /// Requires [selectedDescriptions] to be non-empty. The backend does not
  /// perform its own web search anymore.
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<Map<String, dynamic>> generateSummary(WineData wineData, {required List<Map<String, String>> selectedDescriptions}) async {
    if (selectedDescriptions.isEmpty) {
      throw ArgumentError("At least one description must be selected to generate a summary.",);
    }

    final query = wineData.toUriComponent();
    
    final response = await postJson(
      "generateSummary",
      body: {
        "q": query,
        "descriptions": selectedDescriptions,
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Failed to fetch summary");
    }
  
    return jsonDecode(response.body);
  }


  /// Analyzes wine label images using Gemini AI.
  /// 
  /// Takes front and back label images and extracts wine information
  /// including name, winery, vintage, grape variety, etc.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<WineData> analyzeLabel(Uint8List frontBytes, Uint8List backBytes) async {
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


  /// Fetches the search history of the user.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<List<StoredWine>> getSearchHistory() async {
    final response = await get("searchHistory");
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


  /// Deletes the stored wine entry from the database.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<void> deleteSearch(String id) async {
    final response = await post("deleteSearch", id);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Error: Delete failed");
    }
  }
}
