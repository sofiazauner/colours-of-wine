/* logic for summarizing descriptions */

part of 'orchestrator.dart';

extension WineScannerSummaryLogic on _WineScannerPageState {
  
  // get summary from descriptions
  Future<Map<String, dynamic>> fetchSummary() async {
    if (_isLoading) {
      return {};
    }
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final query = _wineData!.toUriComponent();
      final url =
          Uri.parse("$baseURL/generateSummary?token=$token&q=$query");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception("Failed to fetch summary (${response.statusCode})");
      }

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint("Error while fetching summary: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error retrieving summary - Please try again!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 7),
          backgroundColor: Color.fromARGB(255, 210, 8, 8),
          margin: EdgeInsets.all(50),
        ),
      );
      return {};
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
