/* main screen with category tabs and wine overview */

import 'package:flutter/material.dart';
import 'package:colours_of_wine/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wine.dart';
import '../providers/wine_provider.dart';
import '../providers/language_provider.dart';
import '../services/description_cache.dart';
import '../widgets/app_logo.dart';
import '../dialogs/settings_dialog.dart';
import 'wine_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wineProvider = Provider.of<WineProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final List<CategoryTab> categories = [
      CategoryTab(
        title: l10n.meineWeine,
        icon: Icons.wine_bar,
        category: WineCategory.meineWeine,
        wines: wineProvider.meineWeine,
      ),
      CategoryTab(
        title: l10n.favoriten,
        icon: Icons.favorite,
        category: WineCategory.favoriten,
        wines: wineProvider.favoriten,
      ),
      CategoryTab(
        title: l10n.importierteBeschreibungen,
        icon: Icons.import_export,
        category: WineCategory.importierteBeschreibungen,
        wines: wineProvider.importierteBeschreibungen,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const AppLogo(height: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.appTitle)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'signout') {
                DescriptionCache.clear();
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'signout',
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: categories
            .map((cat) => WineListScreen(
                  title: cat.title,
                  category: cat.category,
                  wines: cat.wines,
                ))
            .toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: categories
            .map((cat) => BottomNavigationBarItem(
                  icon: Icon(cat.icon),
                  label: cat.title,
                ))
            .toList(),
      ),
    );
  }
}

class CategoryTab {
  final String title;
  final IconData icon;
  final WineCategory category;
  final List<Wine> wines;

  CategoryTab({
    required this.title,
    required this.icon,
    required this.category,
    required this.wines,
  });
}
