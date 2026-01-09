/* pop-up dialog to add a new description */

import 'package:flutter/material.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import '../models/wine_description.dart';

class AddDescriptionDialog extends StatefulWidget {
  final String? defaultTitle;
  final WineDescription? existingDescription;

  const AddDescriptionDialog({
    super.key,
    this.defaultTitle,
    this.existingDescription,
  });

  @override
  State<AddDescriptionDialog> createState() => _AddDescriptionDialogState();
}

class _AddDescriptionDialogState extends State<AddDescriptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.existingDescription?.source ?? widget.defaultTitle ?? '',
    );
    _urlController = TextEditingController(
      text: widget.existingDescription?.url ?? '',
    );
    _textController = TextEditingController(
      text: widget.existingDescription?.text ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final description = WineDescription(
        id: widget.existingDescription?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        source: _titleController.text.trim(),
        url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
        text: _textController.text.trim(),
        isUsedForSummary: widget.existingDescription?.isUsedForSummary ?? false,
        isExpanded: widget.existingDescription?.isExpanded ?? false,
      );
      Navigator.of(context).pop(description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingDescription != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.edit : l10n.addDescription),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.descriptionTitle,
                    hintText: l10n.descriptionTitleHint,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte geben Sie einen Titel ein';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: l10n.descriptionUrl,
                    hintText: l10n.descriptionUrlHint,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _textController,
                  decoration: InputDecoration(
                    labelText: l10n.descriptionText,
                    hintText: l10n.descriptionTextHint,
                  ),
                  maxLines: 8,
                  minLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bitte geben Sie einen Beschreibungstext ein';
                    }
                    return null;
                  },
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
        ElevatedButton(
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
