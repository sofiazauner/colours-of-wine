/* service layer for HTTP-calls*/

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:colours_of_wine/models/exceptions.dart';
import 'package:colours_of_wine/models/models.dart';
import 'package:colours_of_wine/models/validation.dart';

class WineRepository {
  WineRepository({
    required this.baseURL,
    required this.getToken,
  });

  final String baseURL;
  final Future<String> Function() getToken;

  Future<http.Response> get(String endpoint, {String? query}) async {
    final token = await getToken();
    final url = query == null
        ? Uri.parse("$baseURL/$endpoint?token=$token")
        : Uri.parse("$baseURL/$endpoint?token=$token&q=$query");
    try {
      return await http.get(url);
    } catch (_) {
      throw NetworkException('Network error while contacting the server. Please check your internet connection.');
    }
  }

  Future<http.Response> post(String endpoint, String id) async {
    final token = await getToken();
    final url = Uri.parse("$baseURL/$endpoint?token=$token&id=$id");
    try {
    return await http.post(url);
    } catch (_) {
      throw NetworkException('Failed to send data to the server. Please try again later.');
    }
  }

  Future<http.Response> postJson(String endpoint,
      {required Map<String, dynamic> body}) async {
  final token = await getToken();
  final url = Uri.parse("$baseURL/$endpoint?token=$token");
    try {
  return await http.post(url, headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    } catch (_) {
      throw NetworkException('Unable to communicate with the server while sending data.');
    }
  }

  /// Fetches wine descriptions from the web (SerpApi).
  ///
  /// Returns (historyId, descriptions).
  Future<(String, List<Map<String, String>>)> fetchDescriptions(
      WineData wineData) async {
    final validationResult = WineDataValidator.validate(wineData);
    if (!validationResult.ok) {
      throw ArgumentError("WineData is invalid: ${validationResult.message}");
    }

    final q = wineData.toUriComponent();
    final name = Uri.encodeComponent(wineData.name);

    final response = await get("fetchDescriptions", query: "$q&name=$name");
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, "Search failed");
    }
    final data = jsonDecode(response.body);
    final historyId =
    (data is Map && data['historyId'] != null) ? data['historyId'].toString() : "";

    final List<Map<String, String>> results = [];

    final organic = (data is Map) ? data["organic_results"] : null;
    if (organic is List) {
      for (final item in organic) {
        if (item is Map) {
          final title = item["articleTitle"]?.toString() ??
              item["title"]?.toString() ??
              "";
          final text = item["articleText"]?.toString() ?? "";
          final snippet = item["articleSnippet"]?.toString() ??
              item["snippet"]?.toString() ??
              "";
          final url = item["articleUrl"]?.toString() ??
              item["link"]?.toString() ??
              "";

          results.add({
            "articleTitle": title,
            "articleText": text,
            "snippet": snippet,
            "url": url,
          });
        }
      }
    }

    return (historyId, results);
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
  /// Throws [ApiException] if the API call fails.
  /// Throws [NetworkException] if network connectivity issues occur.
  Future<Map<String, dynamic>> generateSummary(WineData wineData, {required List<Map<String, String>> selectedDescriptions, required String historyId,}) async {
    if (selectedDescriptions.isEmpty) {
      throw ArgumentError("At least one description must be selected to generate a summary.",);
    }

    final query = wineData.toUriComponent();
    
    final response = await postJson(
      "generateSummary",
      body: {
        "q": query,
        "descriptions": selectedDescriptions,
        "historyId": historyId,
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
    return data.map((item) {
      final map = Map<String, dynamic>.from(item);
      return StoredWine.fromJson(map);
    }).toList();
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
