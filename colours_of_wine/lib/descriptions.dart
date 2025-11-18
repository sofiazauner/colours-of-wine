/* logic for getting wine descriptions from the internet */

part of 'orchestrator.dart';

extension WineScannerWebLogic on _WineScannerPageState {

  // web research
  Future<List<Map<String, String>>> _fetchWineDescription() async {
    if (_wineData == null || _isLoading) return []; // check if data is available

    if (_wineData!.grapeVariety.isEmpty) {          // check if variety is given (mandatory)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Grape Variety is mandatory! Please make sure it gets registered and try again!",
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 251)),
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 8),
          backgroundColor: Color.fromARGB(255, 184, 114, 17),
          margin: EdgeInsets.only(
            bottom: 500,
            left: 50,
            right: 50,
          ),
        ),
      );
      return [];
    }

    setState(() => _isLoading = true); // show loading screen

    try {
      final query = _wineData!.toUriComponent();
      final token = await _getToken();
      final wineName = _wineData!.name;
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
    } catch (e) {
      debugPrint("Fehler beim Laden der Beschreibung: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error retrieving wine descriptions - Please try again!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 7),
          backgroundColor: Color.fromARGB(255, 210, 8, 8),
          margin: EdgeInsets.all(50),
        ),
      );
      return [];
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
