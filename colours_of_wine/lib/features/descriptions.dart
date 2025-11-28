/* logic for getting wine descriptions from the internet */

part of 'orchestrator.dart';

extension WineScannerWebLogic on _WineScannerPageState {

  // web research
  Future<List<Map<String, String>>> _fetchWineDescription() async {
    if (_wineData == null || _isLoading) return []; // check if data is available

    if (_wineData!.grapeVariety.isEmpty) {          // check if variety is given (mandatory)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SnackbarMessages.missingGrapeVariety,
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
      return [];
    }

    setState(() => _isLoading = true); // show loading screen

    try {
      final result = await _wineService.fetchDescriptions(_wineData!);
      return result;
    } catch (e) {
      debugPrint("Error retrieving wine descriptions: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SnackbarMessages.descriptionFailed),
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.defaultSnackBarDuration,
          backgroundColor: AppConstants.errorRed,
          margin: EdgeInsets.all(50),
        ),
      );
      return [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
