/* logic for wine data registration (manual) */

part of 'orchestrator.dart';

extension WineScannerManualLogic on _WineScannerPageState {

  Future<void> _enterManually() async {
    final Map<String, TextEditingController> controllers = {
      "Name": TextEditingController(),
      "Winery": TextEditingController(),
      "Vintage": TextEditingController(),
      "Grape Variety": TextEditingController(),
      "Vineyard Location": TextEditingController(),
      "Country": TextEditingController(),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppConstants.manualTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries.map((entry) {
                String label;
                if (entry.key == "Grape Variety") {
                  label = "Grape Variety     (mandatory)";
                } else {
                  label =
                      entry.key[0].toUpperCase() + entry.key.substring(1);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: TextField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppConstants.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                final data = <String, String>{};
                controllers.forEach((key, ctrl) {
                  data[key] = ctrl.text.trim();
                });

                Navigator.pop(context);
                setState(() {
                  _wineData = WineData(data);
                });
              },
              child: const Text(AppConstants.saveButton),
            ),
          ],
        );
      },
    );
  }
}
