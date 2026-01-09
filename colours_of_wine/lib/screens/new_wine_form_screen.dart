/* form to manually edit wine data (name, year, producer, etc.) */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import '../models/wine.dart';
import '../providers/wine_provider.dart';
import '../widgets/app_logo.dart';
import 'wine_detail_screen.dart';
import '../dialogs/add_description_dialog.dart';
import '../models/wine_description.dart';
import 'wine_descriptions_screen.dart';
import '../utils/snackbar_messages.dart';

class NewWineFormScreen extends StatefulWidget {
  final Wine wine;

  const NewWineFormScreen({super.key, required this.wine});

  @override
  State<NewWineFormScreen> createState() => _NewWineFormScreenState();
}

class _NewWineFormScreenState extends State<NewWineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  late TextEditingController _producerController;
  late TextEditingController _regionController;
  late TextEditingController _countryController;
  String? _imageBase64;

  @override
  void initState() {
    super.initState();
    final wine = widget.wine;
    _nameController = TextEditingController(text: wine.name);
    _yearController = TextEditingController(text: wine.year);
    _producerController = TextEditingController(text: wine.producer);
    _regionController = TextEditingController(text: wine.region);
    _countryController = TextEditingController();
    _imageBase64 = wine.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _producerController.dispose();
    _regionController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _generateSummary() async {
    final l10n = AppLocalizations.of(context)!;
    final wineProvider = Provider.of<WineProvider>(context, listen: false);
    
    // update wine with form data first
    final updatedWine = Wine(
      id: widget.wine.id,
      name: _nameController.text.trim().isEmpty ? l10n.unnamed : _nameController.text.trim(),
      year: _yearController.text.trim(),
      producer: _producerController.text.trim(),
      region: _regionController.text.trim(),
      category: widget.wine.category,
      color: widget.wine.color,
      nose: widget.wine.nose,
      palate: widget.wine.palate,
      finish: widget.wine.finish,
      alcohol: widget.wine.alcohol,
      restzucker: widget.wine.restzucker,
      saure: widget.wine.saure,
      vinification: widget.wine.vinification,
      foodPairing: widget.wine.foodPairing,
      colorHex: widget.wine.colorHex,
      imageUrl: _imageBase64,
      descriptions: widget.wine.descriptions,
      isFavorite: widget.wine.isFavorite,
      country: _countryController.text.trim(),
    );
    
    wineProvider.updateWine(updatedWine);
    
    // fetch descriptions if none exist
    if (updatedWine.descriptions.isEmpty) {
      try {
        await wineProvider.fetchDescriptions(updatedWine);
        final reloadedWine = wineProvider.getWineById(widget.wine.id);
        if (reloadedWine != null && reloadedWine.descriptions.isNotEmpty) {
          await wineProvider.generateSummary(reloadedWine);
        }
      } catch (e) {
        if (mounted) {
          SnackbarMessages.show(context, '${l10n.descriptionsLoadFailed}: $e');
        }
      }
    } else {
      try {
        await wineProvider.generateSummary(updatedWine);
      } catch (e) {
        if (mounted) {
          SnackbarMessages.show(context, '${l10n.summaryGenerationFailed}: $e');
        }
      }
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WineDetailScreen(wineId: widget.wine.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(height: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.wine.displayName)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.name),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: InputDecoration(labelText: l10n.year),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _producerController,
                decoration: InputDecoration(labelText: l10n.producer),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(labelText: l10n.region),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryController,
                decoration: InputDecoration(labelText: l10n.country),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final l10n = AppLocalizations.of(context)!;
                        final name = _nameController.text.trim().isEmpty ? l10n.unnamed : _nameController.text.trim();
                        final year = _yearController.text.trim();
                        final defaultTitle = year.isNotEmpty ? '$name $year' : name;
                        final description = await showDialog<WineDescription>(
                          context: context,
                          builder: (context) => AddDescriptionDialog(
                            defaultTitle: defaultTitle,
                          ),
                        );
                        if (description != null) {
                          final wineProvider = Provider.of<WineProvider>(context, listen: false);
                          final updatedWine = Wine(
                            id: widget.wine.id,
                            name: name,
                            year: year,
                            producer: _producerController.text.trim(),
                            region: _regionController.text.trim(),
                            category: widget.wine.category,
                            color: widget.wine.color,
                            nose: widget.wine.nose,
                            palate: widget.wine.palate,
                            finish: widget.wine.finish,
                            alcohol: widget.wine.alcohol,
                            restzucker: widget.wine.restzucker,
                            saure: widget.wine.saure,
                            vinification: widget.wine.vinification,
                            foodPairing: widget.wine.foodPairing,
                            colorHex: widget.wine.colorHex,
                            imageUrl: _imageBase64,
                            descriptions: [description, ...widget.wine.descriptions],
                            isFavorite: widget.wine.isFavorite,
                            country: _countryController.text.trim(),
                          );
                          wineProvider.updateWine(updatedWine);
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WineDescriptionsScreen(wineId: widget.wine.id),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.edit_note),
                      label: Text(l10n.describeWine),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _generateSummary,
                      icon: const Icon(Icons.search),
                      label: Text(l10n.searchWineDescriptions),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
