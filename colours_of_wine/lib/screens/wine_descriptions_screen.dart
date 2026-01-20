/* displays and manages wine descriptions (search, select, add custom) */

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import '../providers/wine_provider.dart';
import '../models/wine_description.dart';
import '../widgets/app_logo.dart';
import 'wine_detail_screen.dart';
import '../dialogs/add_description_dialog.dart';
import '../utils/snackbar_messages.dart';

class WineDescriptionsScreen extends StatefulWidget {
  final String wineId;
  final String _uniqueId;           // internal unique identifier for this screen instance

  WineDescriptionsScreen({
    super.key,
    required this.wineId,
    String? uniqueId,
  }) : _uniqueId = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  State<WineDescriptionsScreen> createState() => _WineDescriptionsScreenState();
}

class _WineDescriptionsScreenState extends State<WineDescriptionsScreen> {
  late final Key _listKey = ValueKey('reorderable_descriptions_${widget.wineId}_${widget._uniqueId}');
  
  @override
  void initState() {
    super.initState();
    // enable default number of descriptions when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final wineProvider = Provider.of<WineProvider>(context, listen: false);
      
      await wineProvider.enableDefaultDescriptionsForSummary(widget.wineId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wineProvider = Provider.of<WineProvider>(context);
    final wine = wineProvider.getWineById(widget.wineId);

    if (wine == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.wineDetail)),
        body: Center(child: Text(l10n.wineNotFound)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(height: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(wine.displayName)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // navigate back to the category list
            Navigator.of(context).popUntil((route) {
              return route.isFirst;
            });
          },
        ),
          actions: [
            // button to select all descriptions
            if (wine.descriptions.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: l10n.selectAllDescriptions,
                onPressed: () {
                  wineProvider.selectAllDescriptions(widget.wineId);
                },
              ),
            // button to search descriptions from internet
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.searchWineDescriptions,
              onPressed: () async {
                try {
                  await wineProvider.fetchDescriptions(wine);
                  if (mounted) {
                    SnackbarMessages.show(context, l10n.descriptionsLoaded);
                  }
                } catch (e) {
                  if (mounted) {
                    SnackbarMessages.show(context, '${l10n.descriptionsLoadFailed}: $e');
                  }
                }
              },
            ),
            // button to show summary and visualization
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: l10n.showSummaryAndVisualization,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WineDetailScreen(wineId: wine.id),
                  ),
                );
              },
            ),
          ],
        ),
      body: wine.descriptions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.noDescriptionsAvailable,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // search descriptions from internet
                        try {
                          await wineProvider.fetchDescriptions(wine);
                          if (mounted) {
                            SnackbarMessages.show(context, l10n.descriptionsLoaded);
                          }
                        } catch (e) {
                          if (mounted) {
                            SnackbarMessages.show(context, '${l10n.descriptionsLoadFailed}: $e');
                          }
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: Text(l10n.searchWineDescriptions),
                    ),
                  ],
                ),
              ),
            )
          : ReorderableListView.builder(
              key: _listKey,
              padding: const EdgeInsets.all(16),
              itemCount: wine.descriptions.length,
              onReorder: (oldIndex, newIndex) {
                wineProvider.reorderDescriptions(widget.wineId, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final description = wine.descriptions[index];
                return _DescriptionCard(
                  key: ValueKey('desc_${widget._uniqueId}_${widget.wineId}_${description.id}_$index'),
                  wineId: widget.wineId,
                  description: description,
                  wineProvider: wineProvider,
                );
              },
            ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'add_description_${widget.wineId}',
              onPressed: () async {
                final description = await showDialog<WineDescription>(
                  context: context,
                  builder: (context) => AddDescriptionDialog(
                    defaultTitle: wine.displayName,
                  ),
                );
                if (description != null && mounted) {
                  wineProvider.addDescription(widget.wineId, description);
                }
              },
              child: const Icon(Icons.add),
              tooltip: l10n.addDescription,
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'generate_summary_${widget.wineId}',
              onPressed: () async {
                final wine = wineProvider.getWineById(widget.wineId);
                if (wine == null) return;
                // check if at least one description is selected
                final selectedCount = wine.descriptions.where((d) => d.isUsedForSummary).length;
                if (selectedCount == 0) {
                  if (mounted) {
                    SnackbarMessages.show(context, l10n.atLeastOneDescriptionRequired);
                  }
                  return;
                }
                if (mounted) {
                  // show until it is done
                  SnackbarMessages.show(context, l10n.generatingSummaryAndPic,duration: Duration(seconds: 60));
                }
                try {
                  // generate summary and image using backend
                  await wineProvider.generateSummary(wine);
                  SnackbarMessages.hide(context);
                  // wait a bit to ensure state is fully updated
                  await Future.delayed(const Duration(milliseconds: 300));
                  // navigate directly to wine detail screen with summary
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WineDetailScreen(wineId: widget.wineId),
                      ),
                    );
                  }
                } catch (e) {
                  SnackbarMessages.hide(context);
                  if (mounted) {
                    SnackbarMessages.show(context, '${l10n.summaryGenerationFailed}: $e');
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.generateSummaryAndVisualization),
            ),
          ],
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatefulWidget {
  final String wineId;
  final WineDescription description;
  final WineProvider wineProvider;

  const _DescriptionCard({
    super.key,
    required this.wineId,
    required this.description,
    required this.wineProvider,
  });

  @override
  State<_DescriptionCard> createState() => _DescriptionCardState();
}

class _DescriptionCardState extends State<_DescriptionCard> {
  bool _isEditing = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.description.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _isExpanded => widget.description.isExpanded;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarMessages.show(context, '${l10n.urlOpenFailed}: $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              // toggle expand when clicking on the tile (but not on checkbox)
              final newExpandedState = !_isExpanded;
              widget.wineProvider.toggleDescriptionExpanded(
                widget.wineId,
                widget.description.id,
                newExpandedState,
              );
              if (!newExpandedState) {
                setState(() {
                  _isEditing = false;
                });
              }
            },
            child: ListTile(
              leading: GestureDetector(
                onTap: () {
                  // handle checkbox click separately
                  widget.wineProvider.toggleDescriptionForSummary(
                    widget.wineId,
                    widget.description.id,
                    !widget.description.isUsedForSummary,
                  );
                },
                child: Checkbox(
                  value: widget.description.isUsedForSummary,
                  onChanged: (bool? value) {
                    widget.wineProvider.toggleDescriptionForSummary(
                      widget.wineId,
                      widget.description.id,
                      value ?? false,
                    );
                  },
                ),
              ),
              title: Text(
                widget.description.source,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: widget.description.url != null && widget.description.url!.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _launchURL(widget.description.url!);
                      },
                      child: Text(
                        widget.description.url!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    tooltip: l10n.deleteDescription,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.deleteDescription),
                          content: Text(l10n.deleteDescriptionConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                widget.wineProvider.removeDescription(
                                  widget.wineId,
                                  widget.description.id,
                                );
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: null,
                          minLines: 5,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: l10n.descriptionTextHint,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                  _textController.text = widget.description.text;
                                });
                              },
                              child: Text(l10n.cancel),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                widget.wineProvider.updateDescriptionText(
                                  widget.wineId,
                                  widget.description.id,
                                  _textController.text,
                                );
                                setState(() {
                                  _isEditing = false;
                                });
                              },
                              child: Text(l10n.save),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.description.text.isEmpty
                              ? l10n.noTextAvailable
                              : widget.description.text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                _textController.text = widget.description.text;
                              });
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(l10n.edit),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
