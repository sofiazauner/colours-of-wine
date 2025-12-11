/* user interface for the descriptions screen */

part of '../features/orchestrator.dart';

extension WineScannerDescriptionView on _WineScannerPageState {

// view for descriptions from web search
void _showDescriptionPopup(List<Map<String, String>> results) {
  final Set<int> selectedIndices = {                               // default select first three or change in settings
    for (int i = 0; i < results.length && i < defaultDescriptionCount; i++) i
  };

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          final int selectedCount = selectedIndices.length;
          const int maxSelectable = AppConstants.maximumDescriptionsForSummary;

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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(AppConstants.descriptionTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                fixedSize: const Size(250, 28),
                              ),
                              icon: const Icon(
                                Icons.edit_document,
                                size: 18,
                              ),
                              label: const Text(AppConstants.generateSumAndImageButton,
                                style: TextStyle(fontSize: 14),
                              ),
                              onPressed: selectedCount == 0
                                  ? null
                                  : () async {
                                      Navigator.of(context).pop();
                                      final selectedDescriptions = selectedIndices.map((i) => results[i]).toList();

                                      setState(() {
                                        _selectedDescriptionsForSummary =
                                            selectedDescriptions;
                                      });

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
                                        debugPrint("Error parsing summary result: $e");
                                      }   
                                  },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // display selectable count etc.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          AppConstants.selectDescriptionsText,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$selectedCount / $maxSelectable",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: selectedCount == 0
                              ? AppConstants.errorRed
                              : AppConstants.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // descriptions list
                  Expanded(
                    child: results.isEmpty
                        ? const Center(
                            child: Text(AppConstants.noDescriptionsText),
                          )
                        : ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final item = results[index];
                              final isSelected =
                                  selectedIndices.contains(index);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // checkbox
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (checked) {
                                        setStateDialog(() {
                                          if (checked == true) {
                                            if (selectedIndices.length >= maxSelectable) {
                                              Flushbar(
                                                message: SnackbarMessages.tooMuchDescriptionsSelected,
                                                backgroundColor: AppConstants.informationOrange,
                                                titleColor: AppConstants.infoTextColour,
                                                duration: AppConstants.defaultSnackBarDuration,
                                                margin: EdgeInsets.only(bottom: 500, left: 50, right: 50,),
                                                borderRadius: BorderRadius.circular(12),
                                              ).show(context);                                            
                                            } else {
                                              selectedIndices.add(index);
                                            }
                                          } else {
                                            selectedIndices.remove(index);
                                          }
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 4),

                                    // text-content
                                    Expanded(
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
                                            style:
                                                const TextStyle(fontSize: 14),
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
                                                  color: AppConstants.urlColour,
                                                  decoration: TextDecoration.underline,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const Divider(height: 16),
                                        ],
                                      ),
                                    ),
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