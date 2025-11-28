/* user interface for the descriptions screen */

part of 'orchestrator.dart';

extension WineScannerDescriptionView on _WineScannerPageState {

  // view for descriptions from web search
  void _showDescriptionPopup(List<Map<String, String>> results) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Wine Descriptions   ||",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 19),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size(250, 28),
                              ),
                              icon: const Icon(
                                Icons.edit_document,
                                size: 18,
                              ),
                              label: const Text(
                                "Generate Summary + Image",
                                style: TextStyle(fontSize: 14),
                              ),
                              onPressed: () async {                   // close pop-up + generate summary/image
                                Navigator.of(context).pop();

                                final result = await fetchSummary();
                                if (!mounted || result.isEmpty) return;

                                try {
                                  final summary = result["summary"] as String;
                                  final approved = result["approved"] as bool;
                                  final imageString = result["image"] as String;
                                  final image = Image.memory(
                                    base64Decode(imageString),
                                  );

                                  setState(() {
                                    _webResult = WineWebResult(
                                      summary,
                                      approved,
                                      image,
                                    );
                                  });
                                } catch (e) {
                                  debugPrint(
                                      "Error parsing summary result: $e");
                                }
                              },
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // descriptions list
                    Expanded(
                      child: results.isEmpty
                          ? const Center(
                              child: Text("No descriptions found."),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final item = results[index];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? "Untitled",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['snippet'] ?? "",
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (item['url'] != null) ...[
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => launchUrl(
                                            Uri.parse(item['url']!),
                                          ),
                                          child: Text(
                                            item['url']!,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Divider(height: 20),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
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