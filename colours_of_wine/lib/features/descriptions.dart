/* logic for getting wine descriptions from the internet */

part of orchestrator;

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

    if (!mounted) return [];
    setState(() => _isLoading = true);

    try {
      // fetchDescriptions returns (historyId, descriptions)
      final (historyId, descriptions) =
      await _wineRepository.fetchDescriptions(_wineData!);

      // store history id for later summary persistence
      _currentHistoryId = historyId;

      DescriptionCache.set(key, descriptions);
      _selectedDescriptionsForSummary = [];
      return descriptions;
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
