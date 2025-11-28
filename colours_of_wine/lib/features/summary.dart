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
      final result = await _wineService.generateSummary(_wineData!);
      return result;
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
