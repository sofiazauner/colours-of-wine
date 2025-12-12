/* user interface for the result screen */

part of '../features/orchestrator.dart';

extension WineScannerResultViews on _WineScannerPageState {

  // generic wine card for displaying wine data
  Widget _buildWineCard(WineData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...data.toMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(                                   // categories
                        "${e.key[0].toUpperCase()}${e.key.substring(1)}:", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.resultTitleCol,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(                                   // entries
                        e.value.isEmpty ? "-" : e.value,             // if nothing found "-"
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppConstants.resultTextCol,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // result view after analyzing label to show registered data
  Widget _buildResultView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 35),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Text(
                AppConstants.wineCradTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                      color: AppConstants.resultTextCol,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            _buildWineCard(_wineData!),
            const SizedBox(height: 20),
            if (_webResult != null) ...[
              const SizedBox(height: 10),
              _webResult!.image,
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _webResult!.approved
                        ? Icons.check_circle
                        : Icons.error,
                    size: 18,
                    color: _webResult!.approved
                        ? AppConstants.successGreen
                        : AppConstants.errorRed,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _webResult!.approved
                        ? AppConstants.summarySucc
                        : AppConstants.summaryFail,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _webResult!.approved
                          ? AppConstants.successGreen
                          : AppConstants.errorRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_webResult!.approved) ...[
                Text(
                  _webResult!.summary,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 20),
            ],
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(                             // start web search
                    icon: const Icon(Icons.search),
                    label: const Text(AppConstants.getDescrButton),
                    onPressed: () async {
                      final result = await _fetchWineDescription();
                      if (result.isEmpty) return;
                      if (!mounted) return;

                      _showDescriptionPopup(result);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppConstants.tryAgainButton),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _wineData = null;
                        _frontBytes = null;
                        _backBytes = null;
                        _webResult = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
