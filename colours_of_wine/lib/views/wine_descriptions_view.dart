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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.add,
                            size: 18,
                          ),
                          onPressed: () async {
                              _showAddDescriptionPopup(setStateDialog, results);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Center(
                          child: Text(
                            AppConstants.addDescriptionText,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),

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

  void _showAddDescriptionPopup(void Function(void Function()) setStateParentDialog, List<Map<String, String>> results) {
    final _context = context;
    showDialog(
      context: context,
      builder: (context) {
        final urlController = TextEditingController();
        String error = "";

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(AppConstants.addDescriptionText,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: "URL",
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          // front label
                          child: const Text(AppConstants.loadFromUrlText),
                          style: ElevatedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final url = urlController.text;
                            try {
                              final (title, text, snippet) = await _wineRepository.addURLDescription(url);
                              final item = {
                                "title": title,
                                "snippet": snippet,
                                "url": url,
                                "articleText": text,
                              };
                              setStateParentDialog(() => results.insert(0, item));
                              Navigator.pop(context);
                            } catch (e) {
                              debugPrint("Error while fetching summary: $e");
                              setStateDialog(() => error = SnackbarMessages.urlFetchFailed);
                            }
                          },
                        ),
                        if (error != "") ...[
                          const SizedBox(width: 5),
                          Text(
                            error,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ElevatedButton.icon(
                          // front label
                          icon: const Icon(Icons.upload_file, size: 20),
                          label: const Text(AppConstants.chooseFileText),
                          style: ElevatedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles();

                            if (result != null) {
                              final bytes = result.files.single.bytes!;
                              final name = result.files.single.name!;
                              String text = "";
                              print("name $name");
                              if (name.toLowerCase().endsWith(".pdf")) {
                                try {
                                  text = await _wineRepository.addFileDescription(bytes, name);
                                } catch (e) {
                                  setStateDialog(() => error = SnackbarMessages.cannotReadPdf);
                                }
                              } else if (name.toLowerCase().endsWith(".txt")) {
                                text = utf8.decode(bytes);
                              } else {
                                setStateDialog(() => error = SnackbarMessages.wrongFileType);
                              }
                              final item = {
                                "title": name,
                                "snippet": "",
                                "url": "",
                                "articleText": text,
                              };
                              setStateParentDialog(() => results.insert(0, item));
                              Navigator.pop(context);
                            }
                          },
                        )
                      ],
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
