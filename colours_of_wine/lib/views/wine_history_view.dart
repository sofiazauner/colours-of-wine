/* user interface for the history screen */

part of '../features/orchestrator.dart';

extension WineScannerViews on _WineScannerPageState {

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
}