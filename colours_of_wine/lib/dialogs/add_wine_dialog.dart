/* pop-up dialog to add a new wine, manual or via label scanning */

import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import '../models/wine.dart';
import '../dialogs/add_description_dialog.dart';
import '../models/wine_description.dart';
import '../providers/wine_provider.dart';
import '../utils/app_constants.dart';
import '../utils/snackbar_messages.dart';
import '../screens/wine_descriptions_screen.dart';

class AddWineDialog extends StatefulWidget {
  final WineCategory category;

  const AddWineDialog({
    super.key,
    required this.category,
  });

  @override
  State<AddWineDialog> createState() => _AddWineDialogState();
}

class _AddWineDialogState extends State<AddWineDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  late TextEditingController _producerController;
  late TextEditingController _regionController;
  late TextEditingController _countryController;
  
  String? _imageBase64;
  Uint8List? _frontBytes;
  Uint8List? _backBytes;
  bool _isScanning = false;
  bool _hasFrontImage = false;
  bool _hasBackImage = false;
  bool _hasAnalyzed = false;              // track if label has been analyzed
  String? _wineId;                        // ID of the wine (temporarily in provider, saved to backend only after generateSummary)
  bool _isFetchingDescriptions = false;   // track if descriptions are being fetched

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _yearController = TextEditingController();
    _producerController = TextEditingController();
    _regionController = TextEditingController();
    _countryController = TextEditingController();
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

  Future<void> _pickImage({required bool isFront}) async {
    if (kIsWeb) {                 // upload pic on web platform
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final bytes = result.files.single.bytes!;
        setState(() {
          if (isFront) {
            _frontBytes = bytes;
            _hasFrontImage = true;
          } else {
            _backBytes = bytes;
            _hasBackImage = true;
          }
          if (isFront) {                // use front image for preview
            final base64String = base64Encode(bytes);
            _imageBase64 = 'data:image/${result.files.single.extension};base64,$base64String';
          }
        });
      }
    } else {        // pick or take image on mobile platforms
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.selectImageSource),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: Text(l10n.camera),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: Text(l10n.gallery),
              ),
            ],
          );
        },
      );
      if (source == null) return;
      
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          if (isFront) {
            _frontBytes = bytes;
            _hasFrontImage = true;
            final base64String = base64Encode(bytes);
            _imageBase64 = 'data:image/jpeg;base64,$base64String';
          } else {
            _backBytes = bytes;
            _hasBackImage = true;
          }
        });
      }
    }
  }


  // analyze label images with AI service
  Future<void> _analyzeLabel() async {
    final l10n = AppLocalizations.of(context)!;
    if (_frontBytes == null || _backBytes == null) {
      SnackbarMessages.show(context, l10n.picMissing);
      return;
    }
    setState(() {
      _isScanning = true;
    });
    try {
      final wineProvider = Provider.of<WineProvider>(context, listen: false);
      final wine = await wineProvider.analyzeLabel(_frontBytes!, _backBytes!);
      
      if (mounted && wine != null) {
        // fill form fields with scanned data
        _nameController.text = wine.name;
        _yearController.text = wine.year;
        _producerController.text = wine.producer;
        _regionController.text = wine.region;
        _countryController.text = wine.country;
        
        // store wine ID - wine is temporarily in provider (not saved to backend yet)
        _wineId = wine.id;
        
        setState(() {
          _isScanning = false;
          _hasAnalyzed = true;
        });
        
        SnackbarMessages.show(context, l10n.labelAnalyzed);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        SnackbarMessages.show(context, l10n.analysisFailed);
      }
    }
  }

  void _removeImage({required bool isFront}) {
    setState(() {
      if (isFront) {
        _frontBytes = null;
        _hasFrontImage = false;
        _imageBase64 = null;
      } else {
        _backBytes = null;
        _hasBackImage = false;
      }
    });
  }

  bool _hasAtLeastOneField() {
    return _nameController.text.trim().isNotEmpty ||
        _yearController.text.trim().isNotEmpty ||
        _producerController.text.trim().isNotEmpty ||
        _regionController.text.trim().isNotEmpty ||
        _countryController.text.trim().isNotEmpty ||
        _imageBase64 != null;
  }

  /// creates a wine from form data and adds it to provider (temporarily, not saved to backend)
  /// returns the wine or null if validation fails
  /// wine is only saved to backend when generateSummary() is called
  Wine? _createWine(WineProvider wineProvider) {
    if (!_hasAtLeastOneField()) {
      return null;
    }

    final l10n = AppLocalizations.of(context)!;

    // if wine already exists (from label analysis), update it with current form data
    if (_wineId != null) {
      final existingWine = wineProvider.getWineById(_wineId!);
      if (existingWine != null) {
        final updatedWine = existingWine.copyWith(
          name: _nameController.text.trim().isEmpty ? l10n.unnamed : _nameController.text.trim(),
          year: _yearController.text.trim(),
          producer: _producerController.text.trim(),
          region: _regionController.text.trim(),
          country: _countryController.text.trim(),
          imageUrl: _imageBase64 ?? existingWine.imageUrl,
          fromImported: widget.category == WineCategory.importierteBeschreibungen ? 'imported' : existingWine.fromImported,
        );
        wineProvider.updateWine(updatedWine);
        return updatedWine;
      }
    }

    // if not, create new wine from form data
    final wine = Wine(
      id: _wineId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty ? l10n.unnamed : _nameController.text.trim(),
      year: _yearController.text.trim(),
      producer: _producerController.text.trim(),
      region: _regionController.text.trim(),
      category: widget.category,
      color: '',
      nose: '',
      palate: '',
      finish: '',
      alcohol: 0.0,
      restzucker: null,
      saure: null,
      vinification: '',
      foodPairing: '',
      colorHex: null,
      country: _countryController.text.trim(),
      imageUrl: _imageBase64,
      fromImported: '',
    );
    
    wineProvider.addWine(wine);
    _wineId = wine.id;
    return wine;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isImport = widget.category == WineCategory.importierteBeschreibungen;

    return AlertDialog(
      title: Text(isImport ? l10n.importWine : l10n.addWine),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.labelFront,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          if (_hasFrontImage && _frontBytes != null)
                            Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppConstants.smallSpacing),
                                    child: Image.memory(
                                      _frontBytes!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(32, 32),
                                    ),
                                    onPressed: () => _removeImage(isFront: true),
                                    tooltip: l10n.removePhoto,
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppConstants.smallSpacing),
                              ),
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(isFront: true),
                                icon: const Icon(Icons.add_photo_alternate, size: 20),
                                label: Text(l10n.frontLabel, style: const TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.labelBack,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          if (_hasBackImage && _backBytes != null)
                            Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppConstants.smallSpacing),
                                    child: Image.memory(
                                      _backBytes!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(32, 32),
                                    ),
                                    onPressed: () => _removeImage(isFront: false),
                                    tooltip: l10n.removePhoto,
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppConstants.smallSpacing),
                              ),
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(isFront: false),
                                icon: const Icon(Icons.add_photo_alternate, size: 20),
                                label: Text(l10n.backLabel, style: const TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: AppConstants.smallSpacing),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.name,
                    prefixIcon: _hasAnalyzed && _nameController.text.trim().isEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Colors.grey)
                        : null,
                    filled: _hasAnalyzed && _nameController.text.trim().isEmpty,
                    fillColor: Colors.grey.shade100,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: l10n.year,
                    prefixIcon: _hasAnalyzed && _yearController.text.trim().isEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Colors.grey)
                        : null,
                    filled: _hasAnalyzed && _yearController.text.trim().isEmpty,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                TextFormField(
                  controller: _producerController,
                  decoration: InputDecoration(
                    labelText: l10n.producer,
                    prefixIcon: _hasAnalyzed && _producerController.text.trim().isEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Colors.grey)
                        : null,
                    filled: _hasAnalyzed && _producerController.text.trim().isEmpty,
                    fillColor: Colors.grey.shade100,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: _regionController,
                  decoration: InputDecoration(
                    labelText: l10n.region,
                    prefixIcon: _hasAnalyzed && _regionController.text.trim().isEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Colors.grey)
                        : null,
                    filled: _hasAnalyzed && _regionController.text.trim().isEmpty,
                    fillColor: Colors.grey.shade100,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                TextFormField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: l10n.country,
                    prefixIcon: _hasAnalyzed && _countryController.text.trim().isEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Colors.grey)
                        : null,
                    filled: _hasAnalyzed && _countryController.text.trim().isEmpty,
                    fillColor: Colors.grey.shade100,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        // analyze Label button - only show when both images are uploaded
        if (widget.category == WineCategory.meineWeine && _hasFrontImage && _hasBackImage)
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _analyzeLabel,
            icon: _isScanning 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isScanning ? l10n.analyzing : l10n.analyzeLabel),
          ),
        ElevatedButton.icon(
          // open add description dialog
          onPressed: () async {
            final wineProvider = Provider.of<WineProvider>(context, listen: false);
            
            final wine = _createWine(wineProvider);
            if (wine == null) {
              SnackbarMessages.show(context, l10n.atLeastOneFieldRequired);
              return;
            }
            final name = _nameController.text.trim().isEmpty ? l10n.unnamed : _nameController.text.trim();
            final year = _yearController.text.trim();
            final defaultTitle = year.isNotEmpty ? '$name $year' : name;
            final description = await showDialog<WineDescription>(
              context: context,
              builder: (context) => AddDescriptionDialog(
                defaultTitle: defaultTitle,
              ),
            );
            if (description != null && _wineId != null) {
              wineProvider.addDescription(_wineId!, description);
              // close dialog and navigate to descriptions screen
              Navigator.of(context).pop();
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WineDescriptionsScreen(
                      wineId: _wineId!,
                    ),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.edit_note),
          label: Text(l10n.describeWine),
        ),
        ElevatedButton.icon(
          // fetch descriptions from internet (via backend  - serpApi)
          onPressed: _isFetchingDescriptions ? null : () async {
            final wineProvider = Provider.of<WineProvider>(context, listen: false);
            
            final wine = _createWine(wineProvider);
            if (wine == null) {
              SnackbarMessages.show(context, l10n.atLeastOneFieldRequired);
              return;
            }
            
            setState(() {
              _isFetchingDescriptions = true;
            });
            
            try {
              await wineProvider.fetchDescriptions(wine);
              
              if (mounted) {
                Navigator.of(context).pop();
                if (_wineId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WineDescriptionsScreen(
                        wineId: _wineId!,
                      ),
                    ),
                  );
                  if (mounted) {
                    SnackbarMessages.show(context, l10n.descriptionsLoaded);
                  }
                }
              }
            } catch (e) {
              if (mounted) {
                Navigator.of(context).pop();
                SnackbarMessages.show(context, '${l10n.descriptionsLoadFailed}: $e');
                if (_wineId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WineDescriptionsScreen(
                        wineId: _wineId!,
                      ),
                    ),
                  );
                }
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isFetchingDescriptions = false;
                });
              }
            }
          },
          icon: _isFetchingDescriptions 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(_isFetchingDescriptions ? l10n.searching : l10n.searchWineDescriptions),
        ),
      ],
    );
  }
}
