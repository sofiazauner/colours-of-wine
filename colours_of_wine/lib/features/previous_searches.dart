/* logic for previous search database */

part of 'orchestrator.dart';

extension WineScannerHistoryLogic on _WineScannerPageState {

  // find previous searches
  Future<List<StoredWine>> _fetchSearchHistory() async {
    if (_isLoading) return [];
    setState(() => _isLoading = true);

    try {
      final scope =
      _collectionScope == WineCollectionScope.mine ? 'mine' : 'others';
      final list = await _wineRepository.getSearchHistory(scope: scope);
      return list;
    } catch (e) {
      debugPrint("Error retrieving wine descriptions: $e");
      SnackbarMessages.showErrorBar(context, SnackbarMessages.descriptionFailed);
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


  // delete previous search entry
  Future<void> _deleteStoredWine(String id) async {
    try {
      await _wineRepository.deleteSearch(id);

      setState(() {
        _pastWineData!.removeWhere((w) => w.id == id); // remove from local list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            SnackbarMessages.deleteSuccess,
            style: TextStyle(color: AppConstants.infoTextColour),
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.defaultSnackBarDuration,
          backgroundColor: AppConstants.informationOrange,
          margin: EdgeInsets.only(
            bottom: 500,
            left: 50,
            right: 50,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Delete error: $e");
      SnackbarMessages.showErrorBar(context, SnackbarMessages.deleteFailed);
    }
  }
}
