/* logic for getting wine descriptions from the internet */

part of 'orchestrator.dart';

extension WineScannerWebLogic on _WineScannerPageState {

  // web research
  Future<List<Map<String, String>>> _fetchWineDescription() async {
    if (_wineData == null || _isLoading) return []; // check if data is available

    if (_wineData!.grapeVariety.isEmpty) {          // check if variety is given (mandatory)
      SnackbarMessages.showErrorBar(context, SnackbarMessages.missingGrapeVariety);
      return [];
    }

    setState(() => _isLoading = true); // show loading screen

    try {
      final result = await _wineService.fetchDescriptions(_wineData!);
      return result;
    } catch (e) {
      debugPrint("Error retrieving wine descriptions: $e");
      SnackbarMessages.showErrorBar(context, SnackbarMessages.descriptionFailed);
      return [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
