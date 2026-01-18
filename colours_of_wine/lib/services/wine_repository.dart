/* service layer for HTTP-calls*/

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/src/response.dart';
import 'package:colours_of_wine/models/wine.dart';
import 'package:colours_of_wine/models/exceptions.dart';
import 'package:colours_of_wine/utils/app_constants.dart';
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
      AppConstants.httpTimeout,
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
      AppConstants.httpTimeout,
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
      AppConstants.httpTimeout,
      onTimeout: () {
        throw NetworkException('Request timed out');
      },
    );
  }

  Future<T> retry<T>(Future<T> Function() fn, {int maxRetries = AppConstants.maxRetries}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(AppConstants.retryDelay);
      }
    }
    throw NetworkException("Max retries exceeded");
  }

  /// Fetches the wine descriptions from Serp API.
  ///
  /// Takes a Wine object.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<List<Map<String, String>>> fetchDescriptions(Wine wine) async {
    final query = wine.toUriComponent();
    final wineName = wine.name;
    final response = await get("fetchDescriptions", query: query, name: wineName);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Search failed");
    }
    final data = jsonDecode(response.body);
    final results = <Map<String, String>>[];
    for (var item in data) {
      results.add({
        "title": item['title'] ?? "No title",
        "snippet": item['snippet'] ?? "",
        "url": item['url'] ?? "",
        "articleText": item['articleText'] ?? "",
      });
    }
    return results;
  }


  /// Extracts a description from the uploaded file.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<String> addFileDescription(Uint8List bytes, String name) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseURL/addFileDescription?token=$token"),
    );

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      contentType: MediaType.parse('application/octet-stream'),
      filename: name,
    ));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Failed to add description");
    }
    return await response.stream.bytesToString();
  }


  /// Extracts a description from the URL supplied.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<(String, String, String)> addURLDescription(String url) async {
    final query = Uri.encodeComponent(url);
    final response = await get("addURLDescription", query: query);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Failed to load URL");
    }

    final res = jsonDecode(response.body);

    return (res["title"].toString(), res["text"].toString(), res["snippet"].toString());
  }


  /// Generates a wine summary using Gemini AI Agentic Reviewer Loop and selected descriptions.
  /// 
  /// Requires [selectedDescriptions] to be non-empty. The backend does not
  /// perform its own web search anymore.
  /// Sends complete wine data to backend for storage.
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<Map<String, dynamic>> generateSummary(
    Wine wine, {
    required List<Map<String, String>> selectedDescriptions,
    Map<String, dynamic>? wineInfo, // Complete wine info for storage
  }) async {
    if (selectedDescriptions.isEmpty) {
      throw ArgumentError("At least one description must be selected to generate a summary.",);
    }

    final query = wine.toUriComponent();
    
    final body = {
      "q": query,
      "descriptions": selectedDescriptions,
    };
    
    // Add complete wine info if provided (for storage in backend)
    if (wineInfo != null) {
      body["wineInfo"] = wineInfo;
    }
    
    final response = await postJson(
      "generateSummary",
      body: body,
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
  /// Returns a Map with the extracted data.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<Map<String, String>> analyzeLabel(Uint8List frontBytes, Uint8List backBytes) async {
    final token = await getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseURL/callGemini?token=$token"),
    );

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

    return Map<String, String>.from(decoded);
  }


  /// Fetches the search history of the user.
  /// Returns list of Wine objects directly from backend.
  /// 
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<List<Wine>> getSearchHistory() async {
    final response = await get("searchHistory");
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Search failed");
    }

    final List<dynamic> data = jsonDecode(response.body);
    final List<Wine> list = data.map((item) {
      final map = Map<String, dynamic>.from(item);
      // Add category for "meine Weine"
      map['category'] = 'meineWeine';
      return Wine.fromJson(map);
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
