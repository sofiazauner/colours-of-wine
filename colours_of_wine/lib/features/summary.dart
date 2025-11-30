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
      SnackbarMessages.showErrorBar(context, SnackbarMessages.summaryFailed);
      return {};
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
