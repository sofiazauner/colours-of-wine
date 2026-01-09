/* pop-up dialog to adjust settings (language/default description picking) */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colours_of_wine/providers/language_provider.dart';
import 'package:colours_of_wine/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import 'package:colours_of_wine/utils/snackbar_messages.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _defaultDescriptionCount = AppConstants.defaultSelectedDescriptionsCount;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultDescriptionCount();
  }

  // functions for default description selection count
  Future<void> _loadDefaultDescriptionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(AppConstants.defaultDescriptionCountKey);
      if (count != null) {
        setState(() {
          _defaultDescriptionCount = count;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading default description count: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDefaultDescriptionCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(AppConstants.defaultDescriptionCountKey, count);
    } catch (e) {
      debugPrint('Error saving default description count: $e');
    }
  }

  // build method
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.dialogPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Text(
              l10n.settings,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
            ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.largeSpacing),
            // language selection
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.mediumSpacing),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<Locale>(
                    title: Text(l10n.german),
                    value: const Locale('de', ''),
                    groupValue: languageProvider.locale,
                    onChanged: (Locale? value) {
                      if (value != null) {
                        languageProvider.setLanguage(value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<Locale>(
                    title: Text(l10n.english),
                    value: const Locale('en', ''),
                    groupValue: languageProvider.locale,
                    onChanged: (Locale? value) {
                      if (value != null) {
                        languageProvider.setLanguage(value);
                      }
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ), 
            const SizedBox(height: AppConstants.largeSpacing),
            // default description selection counter
            Text(
              l10n.defaultDescriptionCount,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppConstants.mediumSpacing),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Slider(
                    value: _defaultDescriptionCount.toDouble(),
                    min: 0,
                    max: AppConstants.maximumDescriptionsForSummary.toDouble(),
                    divisions: AppConstants.maximumDescriptionsForSummary,
                    label: '$_defaultDescriptionCount',
                    onChanged: (value) {
                      setState(() {
                        _defaultDescriptionCount = value.toInt();
                      });
                    },
                  ),
                  Text(
                    '${l10n.currently}: $_defaultDescriptionCount',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            const SizedBox(height: AppConstants.largeSpacing),
            // save button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _saveDefaultDescriptionCount(_defaultDescriptionCount);
                    if (mounted) {
                      Navigator.of(context).pop();
                      SnackbarMessages.show(
                        context, 
                        l10n.saved,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
