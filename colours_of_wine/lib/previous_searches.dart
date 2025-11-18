/* logic for previous search database */

part of 'orchestrator.dart';

extension WineScannerHistoryLogic on _WineScannerPageState {

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
      final url = Uri.parse("$baseURL/deleteSearch").replace(
        // remove from database
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
        _pastWineData!.removeWhere((w) => w.id == id); // remove from local list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Entry was successfully deleted!",
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 251)),
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          backgroundColor: Color.fromARGB(255, 184, 114, 17),
          margin: EdgeInsets.only(
            bottom: 500,
            left: 50,
            right: 50,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete entry - Please try again!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
