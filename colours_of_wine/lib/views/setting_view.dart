/* user interface for setting screen */

part of '../features/orchestrator.dart';

extension WineScannerSettingsView on _WineScannerPageState {

  Future<void> showSettingPopup() async {
    int defaultVal = defaultDescriptionCount;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(AppConstants.settingsTitle,
                            style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(AppConstants.defaultDescriptionSelectionText,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.left,
                      )
                    ),
                    Slider(
                      value: defaultVal.toDouble(),
                      min: 0,
                      max: AppConstants.maximumDescriptionsForSummary.toDouble(),
                      divisions: AppConstants.maximumDescriptionsForSummary,
                      label: "$defaultVal",
                      onChanged: (value) {
                        setStateDialog(() {
                          defaultVal = value.toInt();
                        });
                      },
                    ),
                    Text("Currently: $defaultVal",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              defaultDescriptionCount = defaultVal;
                            });
                            Navigator.pop(dialogContext);
                          },
                          child: const Text(AppConstants.saveButton),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
