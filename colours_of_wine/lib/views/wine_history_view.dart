/* user interface for the history screen */

part of orchestrator;

extension WineScannerHistoryView on _WineScannerPageState {
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
                color: AppConstants.deleteButtonColor,
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
                    color: AppConstants.redEmoji,
                  ),
                ),
                const SizedBox(height: 8),
                if (item.createdAt != null) ...[
                  Text(
                    DateFormat.yMMMMd().add_jm().format(item.createdAt!.toLocal()),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppConstants.dateColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.descriptions.isNotEmpty) ...[
                  const Text(AppConstants.descripTitle,
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
                  const Text(AppConstants.emptyDescr,
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
    final List<StoredWine> items = _pastWineData ?? [];

    final String q = _searchQuery.trim().toLowerCase();
    final List<StoredWine> visibleItems = q.isEmpty
        ? items
        : items.where((w) => w.name.toLowerCase().contains(q)).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: Text(
              AppConstants.historyTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.normal,
                    color: AppConstants.redEmoji,
                  ),
            ),
          ),
          const SizedBox(height: 20),

          // search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: AppConstants.searchHintText,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppConstants.borderColor,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      filled: true,
                      prefixIcon: Icon(Icons.wine_bar),
                      prefixIconColor: AppConstants.redEmoji,
                      fillColor: AppConstants.fillColor,
                    ),
                    onSubmitted: (value) {
                      if (!mounted) return;
                      setState(() {
                        _searchQuery = value.trim();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: AppConstants.searchInHistoryButton,
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      _searchQuery = _searchController.text.trim();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // list
          Expanded(
            child: visibleItems.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      AppConstants.emptySearch,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : ListView.builder(
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final e = visibleItems[index];
                      return Column(
                        children: [
                          _buildStoredWineCard(e),
                          const SizedBox(height: 1),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppConstants.resetSearch),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 7),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text(AppConstants.closeButton),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      if (!mounted) return;
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