/* logic for getting wine descriptions from the internet */

part of 'orchestrator.dart';

extension WineScannerWebLogic on _WineScannerPageState {

  // web research
  Future<List<Map<String, String>>> _fetchWineDescription() async {
    if (_wineData == null || _isLoading) return []; // check if data is available

    final validationResult = WineDataValidator.validate(_wineData!);
    if (!validationResult.ok) {          // check if variety is given (mandatory)
      SnackbarMessages.showErrorBar(context, SnackbarMessages.missingGrapeVariety);
      return [];
    }

    final key = _wineData!.toUriComponent();      // check if wine-descriptions are already in cache
    if (DescriptionCache.has(key)) { 
      _selectedDescriptionsForSummary = [];
      return DescriptionCache.get(key)!;
    }

    setState(() => _isLoading = true);            // show loading screen

    try {
      final result = await _wineRepository.fetchDescriptions(_wineData!);
      DescriptionCache.set(key, result);          // add descriptions to cache
      _selectedDescriptionsForSummary = [];
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
