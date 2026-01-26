/* shows complete wine details with infromations and visualizations */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import '../providers/wine_provider.dart';
import '../providers/language_provider.dart';
import '../models/wine.dart';
import '../widgets/wine_color_circle.dart';
import '../widgets/restzucker_chart.dart';
import '../widgets/app_logo.dart';
import 'new_wine_form_screen.dart';
import 'wine_descriptions_screen.dart';
import '../dialogs/add_description_dialog.dart';
import '../models/wine_description.dart';
import '../utils/snackbar_messages.dart';

class WineDetailScreen extends StatefulWidget {
  final String wineId;
  final String _uniqueId;           // internal unique identifier for this screen instance

  WineDetailScreen({
    super.key,
    required this.wineId,
    String? uniqueId,
  }) : _uniqueId = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  State<WineDetailScreen> createState() => _WineDetailScreenState();
}

class _WineDetailScreenState extends State<WineDetailScreen> {
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
    
    return Consumer<WineProvider>(
      builder: (context, wineProvider, _) {
        final wine = wineProvider.getWineById(widget.wineId);

        if (wine == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.wineDetail)),
            body: Center(child: Text(l10n.wineNotFound)),
          );
        }

        if (wineProvider.isNewWine(wine) && 
            wine.descriptions.isEmpty &&
            (wine.category == WineCategory.meineWeine || 
             wine.category == WineCategory.importierteBeschreibungen)) {
          return NewWineFormScreen(wine: wine);
        }

        // show detail screen (with or without summary)
        return _buildDetailScreen(context, l10n, wineProvider, wine);
      },
    );
  }

  Widget _buildDetailScreen(BuildContext context, AppLocalizations l10n, WineProvider wineProvider, Wine wine) {

    late final Key _listKey = ValueKey('reorderable_descriptions_${widget.wineId}_${widget._uniqueId}');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(height: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(wine.displayName)),
            // mark if wine is impoted from "imoirted wines"
            if (wine.fromImported == 'imported' && wine.category == WineCategory.meineWeine)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.import_export,
                      size: 22,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.imported,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
          // button to toggle all descriptions (select/deselect all)
          if (wine.descriptions.isNotEmpty)
            Builder(
              builder: (context) {
                final allSelected = wine.descriptions.isNotEmpty && 
                    wine.descriptions.every((desc) => desc.isUsedForSummary);
                return IconButton(
                  icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
                  tooltip: allSelected 
                      ? (l10n.localeName == 'de' ? 'Alle abwählen' : 'Deselect All')
                      : l10n.selectAllDescriptions,
                  onPressed: () {
                    wineProvider.selectAllDescriptions(widget.wineId);
                  },
                );
              },
            ),
          IconButton(
            icon: Icon(wine.isFavorite ? Icons.favorite : Icons.favorite_border),
            color: wine.isFavorite ? Colors.red : null,
            onPressed: () {
              wineProvider.toggleFavorite(widget.wineId);
            },
            tooltip: wine.isFavorite
                ? l10n.removeFromFavorites
                : l10n.addToFavorites,
          ),
          Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.language),
                onSelected: (String value) {
                  final newLocale = value == 'de' 
                      ? const Locale('de', '') 
                      : const Locale('en', '');
                  languageProvider.setLanguage(newLocale);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'de',
                    child: Row(
                      children: [
                        if (languageProvider.locale.languageCode == 'de')
                          const Icon(Icons.check, size: 20),
                        if (languageProvider.locale.languageCode == 'de')
                          const SizedBox(width: 8),
                        Text(l10n.german),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'en',
                    child: Row(
                      children: [
                        if (languageProvider.locale.languageCode == 'en')
                          const Icon(Icons.check, size: 20),
                        if (languageProvider.locale.languageCode == 'en')
                          const SizedBox(width: 8),
                        Text(l10n.english),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // producer and Region
            if (wine.producer.isNotEmpty)
              _buildInfoRow(context, l10n.producer, wine.producer),
            if (wine.producer.isNotEmpty && wine.region.isNotEmpty)
              const SizedBox(height: 8),
            if (wine.region.isNotEmpty)
              _buildInfoRow(context, l10n.region, wine.region),
            if (wine.year.isNotEmpty) ...[
              if (wine.producer.isNotEmpty || wine.region.isNotEmpty)
                const SizedBox(height: 8),
              _buildInfoRow(context, l10n.year, wine.year),
            ],
            
            // color text and visualization
            if (wine.color.isNotEmpty || 
                wine.imageUrl != null && wine.imageUrl!.isNotEmpty ||
                (wine.category == WineCategory.importierteBeschreibungen && wine.colorHex != null)) ...[
              const SizedBox(height: 24),
              
              if (wine.color.isNotEmpty) ...[
                Text(
                  l10n.color,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  wine.color,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
              ],
              // color Circle Visualization with Restzucker Bar
              // imported wines -> show generated image if available, otherwise show hex circle (or fixed pic von Anja ig)
              if (wine.category == WineCategory.importierteBeschreibungen)
                if (wine.imageUrl != null && wine.imageUrl!.isNotEmpty)
                  // show generated image (if recently generated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImage(wine.imageUrl!),
                    ),
                  )
                else
                  // show hex circle for imported wines without generated image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      WineColorCircle(
                        colorHex: wine.colorHex,
                        colorDescription: wine.color,
                      ),
                      if (wine.restzucker != null) ...[
                        const SizedBox(width: 16),
                        RestzuckerChart(restzucker: wine.restzucker!, width: 20),
                      ],
                    ],
                  )
              else
                // for other categories (meineWeine): show generated image
                if (wine.imageUrl != null && wine.imageUrl!.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImage(wine.imageUrl!),
                        ),
                      ),
                      /* if (wine.restzucker != null) ...[
                        const SizedBox(width: 16),
                        RestzuckerChart(restzucker: wine.restzucker!, width: 20),
                      ], */ //..... prof prees version, but I think it is better than ours, maybe we can use it (?)
                    ],
                  )
            ],
            
            const SizedBox(height: 32),

            Container(
              width: double.infinity,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: ExpansionTile(
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  expandedAlignment: Alignment.topLeft,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(l10n.generatedDescription),
                  children: [
                    // alcohol
                    if (wine.alcohol > 0)
                      _buildInfoRow(context, l10n.alcohol, '${wine.alcohol.toStringAsFixed(1)}%'),
                    
                    if (wine.saure != null) ...[
                      if (wine.alcohol > 0) const SizedBox(height: 8),
                      _buildInfoRow(context, l10n.saure, '${wine.saure!.toStringAsFixed(1)} ${l10n.saureUnit}'),
                    ],
                    
                    if (wine.nose.isNotEmpty || wine.palate.isNotEmpty || wine.finish.isNotEmpty ||
                        wine.vinification.isNotEmpty || wine.foodPairing.isNotEmpty)
                      const SizedBox(height: 24),
                    
                    // nose
                    if (wine.nose.isNotEmpty)
                      _buildSection(
                        context,
                        l10n.nose,
                        wine.nose,
                      ),
                    
                    // palate
                    if (wine.palate.isNotEmpty)
                      _buildSection(
                        context,
                        l10n.palate,
                        wine.palate,
                      ),
                    
                    // finish
                    if (wine.finish.isNotEmpty)
                      _buildSection(
                        context,
                        l10n.finish,
                        wine.finish,
                      ),
                    
                    // vinification
                    if (wine.vinification.isNotEmpty)
                      _buildSection(
                        context,
                        l10n.vinification,
                        wine.vinification,
                      ),
                    
                    // food pairing
                    if (wine.foodPairing.isNotEmpty)
                      _buildSection(
                        context,
                        l10n.foodPairing,
                        wine.foodPairing,
                      ),
                  ]
                )
              ),
            ),

            ReorderableListView.builder(
              key: _listKey,
              padding: const EdgeInsets.only(left: 16, right: 16),
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: wine.descriptions.length,
              onReorder: (oldIndex, newIndex) {
                wineProvider.reorderDescriptions(widget.wineId, oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final description = wine.descriptions[index];
                return DescriptionCard(
                  key: ValueKey('desc_${widget._uniqueId}_${widget.wineId}_${description.id}_$index'),
                  wineId: widget.wineId,
                  description: description,
                  wineProvider: wineProvider,
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                final description = await showDialog<WineDescription>(
                  context: context,
                  builder: (context) => AddDescriptionDialog(
                    defaultTitle: wine.displayName,
                  ),
                );
                if (description != null) {
                  final wineProvider = Provider.of<WineProvider>(context, listen: false);
                  wineProvider.addDescription(wine.id, description);
                }
              },
              child: const Icon(Icons.add),
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
          ]
        )
      )
    );
  }

  Widget _buildImage(String imageUrl) {
    try {
      final imageData = imageUrl.split(',').last;
      return Center(
        child: Image.memory(
          base64Decode(imageData),
          width: 250,
          height: 250,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 250,
              height: 250,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 64),
            );
          },
        ),
      );
    } catch (e) {
      return Center(
        child: Container(
          width: 250,
          height: 250,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 64),
        ),
      );
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
