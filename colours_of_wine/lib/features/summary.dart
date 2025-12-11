/* logic for summarizing descriptions */

part of 'orchestrator.dart';

extension WineScannerSummaryLogic on _WineScannerPageState {
  
  // get summary from (user-selected) descriptions
  Future<Map<String, dynamic>> fetchSummary() async {
    if (_isLoading) {
      return {};
    }
     if (_selectedDescriptionsForSummary.isEmpty) {
      SnackbarMessages.showErrorBar(context, SnackbarMessages.noDescriptionsSelected);
      return {};
    }
    setState(() => _isLoading = true);
    
    try {
      final result = await _wineRepository.generateSummary(_wineData!,  selectedDescriptions: _selectedDescriptionsForSummary);
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
