/* user interfaces for the different screens */

part of 'orchestrator.dart';

extension WineScannerViews on _WineScannerPageState {

  // regular homescreen (first thing you see after login)
  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 230,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          "Discover you wine",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_camera),
          label: const Text("Scan label"),
          onPressed: _takePhotos,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Fill data in manually"),
          onPressed: _enterManually,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text("Previous searches"),
          onPressed: _showSearchHistory,
        ),
      ],
    );
  }


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
                          color: Colors.grey.shade800,
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
                          color: Color.fromARGB(255, 0, 0, 0),
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


  // wine card for previous searches
  Widget _buildStoredWineCard(StoredWine item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Stack(
        children: [
          Positioned(
            right: 6,
            top: 6,
            child: InkWell(
              onTap: () => _deleteStoredWine(item.id),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color.fromARGB(255, 111, 101, 25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? "(No name)" : item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 113, 9, 9),
                  ),
                ),
                const SizedBox(height: 8),
                if (item.createdAt != null) ...[
                  Text(
                    DateFormat.yMMMMd().add_jm().format(
                          item.createdAt!.toLocal(),
                        ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 71, 69, 69),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.descriptions.isNotEmpty) ...[
                  const Text(
                    "Descriptions:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...item.descriptions.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "• $d",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ] else
                  const Text(
                    "No descriptions saved.",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // previous searches view
  Widget _buildHistoryView() {
    // filter for searching option
    final List<StoredWine> visibleItems = _pastWineData!.where((w) => _searchQuery.isEmpty || w.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Text(
              "Previous Searches:",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: Color.fromARGB(255, 113, 9, 9),
                  ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search for a wine name",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 236, 111, 111),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      filled: true,
                      prefixIcon: Icon(Icons.wine_bar),
                      prefixIconColor: Color.fromARGB(255, 113, 9, 9),
                      fillColor: Color.fromARGB(255, 249, 246, 233),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: "Search",
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.trim();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (visibleItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "No entries found.",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...visibleItems.map(
              (e) => Column(
                children: [
                  _buildStoredWineCard(e),
                  const SizedBox(height: 1),
                ],
              ),
            ),
          const SizedBox(height: 1),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Reset Search"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 7),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Close"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _pastWineData = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
                "Registered Information:",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.normal,
                      color: const Color.fromARGB(255, 0, 0, 0),
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
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _webResult!.approved
                        ? "AI Summary:"
                        : "There was an issue with the summary - Please try again!",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _webResult!.approved
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _webResult!.summary,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(                             // start web search
                    icon: const Icon(Icons.search),
                    label: const Text("Get Wine Descriptions"),
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
                    label: const Text("Try again"),
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