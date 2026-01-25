import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Colours of Wine'**
  String get appTitle;

  /// No description provided for @meineWeine.
  ///
  /// In en, this message translates to:
  /// **'My Wines'**
  String get meineWeine;

  /// No description provided for @importierteBeschreibungen.
  ///
  /// In en, this message translates to:
  /// **'Imported Descriptions'**
  String get importierteBeschreibungen;

  /// No description provided for @favoriten.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoriten;

  /// No description provided for @wineDetail.
  ///
  /// In en, this message translates to:
  /// **'Wine Details'**
  String get wineDetail;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @nose.
  ///
  /// In en, this message translates to:
  /// **'Nose'**
  String get nose;

  /// No description provided for @palate.
  ///
  /// In en, this message translates to:
  /// **'Palate'**
  String get palate;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @alcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get alcohol;

  /// No description provided for @restzucker.
  ///
  /// In en, this message translates to:
  /// **'Residual Sugar'**
  String get restzucker;

  /// No description provided for @restzuckerUnit.
  ///
  /// In en, this message translates to:
  /// **'g/l'**
  String get restzuckerUnit;

  /// No description provided for @saure.
  ///
  /// In en, this message translates to:
  /// **'Acidity'**
  String get saure;

  /// No description provided for @saureUnit.
  ///
  /// In en, this message translates to:
  /// **'g/l'**
  String get saureUnit;

  /// No description provided for @vinification.
  ///
  /// In en, this message translates to:
  /// **'Vinification & Aging'**
  String get vinification;

  /// No description provided for @foodPairing.
  ///
  /// In en, this message translates to:
  /// **'Food Pairing'**
  String get foodPairing;

  /// No description provided for @producer.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get producer;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get year;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// No description provided for @noWines.
  ///
  /// In en, this message translates to:
  /// **'No wines found'**
  String get noWines;

  /// No description provided for @noWinesInCategory.
  ///
  /// In en, this message translates to:
  /// **'No wines in this category yet.'**
  String get noWinesInCategory;

  /// No description provided for @addWine.
  ///
  /// In en, this message translates to:
  /// **'Add Wine'**
  String get addWine;

  /// No description provided for @importWine.
  ///
  /// In en, this message translates to:
  /// **'Import Wine'**
  String get importWine;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @colorHex.
  ///
  /// In en, this message translates to:
  /// **'Color Code (Hex)'**
  String get colorHex;

  /// No description provided for @colorHexHint.
  ///
  /// In en, this message translates to:
  /// **'#RRGGBB (optional)'**
  String get colorHexHint;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @atLeastOneFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill at least one field'**
  String get atLeastOneFieldRequired;

  /// No description provided for @descriptions.
  ///
  /// In en, this message translates to:
  /// **'Descriptions'**
  String get descriptions;

  /// No description provided for @noDescriptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No individual descriptions available'**
  String get noDescriptionsAvailable;

  /// No description provided for @usedForSummary.
  ///
  /// In en, this message translates to:
  /// **'Used for summary'**
  String get usedForSummary;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @openLink.
  ///
  /// In en, this message translates to:
  /// **'Open Link'**
  String get openLink;

  /// No description provided for @deleteWine.
  ///
  /// In en, this message translates to:
  /// **'Delete Wine'**
  String get deleteWine;

  /// No description provided for @deleteWineConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this wine?'**
  String get deleteWineConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @generateSummaryAndVisualization.
  ///
  /// In en, this message translates to:
  /// **'Generate Visualization and Summary'**
  String get generateSummaryAndVisualization;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search wine...'**
  String get searchHint;

  /// No description provided for @sortByNone.
  ///
  /// In en, this message translates to:
  /// **'No sorting'**
  String get sortByNone;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get sortByName;

  /// No description provided for @sortByYear.
  ///
  /// In en, this message translates to:
  /// **'By year'**
  String get sortByYear;

  /// No description provided for @showSummaryAndVisualization.
  ///
  /// In en, this message translates to:
  /// **'Show summary and visualization'**
  String get showSummaryAndVisualization;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @searchWineDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Search corresponding wine descriptions'**
  String get searchWineDescriptions;

  /// No description provided for @describeWine.
  ///
  /// In en, this message translates to:
  /// **'Describe wine'**
  String get describeWine;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Add description'**
  String get addDescription;

  /// No description provided for @descriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get descriptionTitle;

  /// No description provided for @descriptionTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Name Year'**
  String get descriptionTitleHint;

  /// No description provided for @descriptionUrl.
  ///
  /// In en, this message translates to:
  /// **'Web link (optional)'**
  String get descriptionUrl;

  /// No description provided for @descriptionUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://...'**
  String get descriptionUrlHint;

  /// No description provided for @descriptionText.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionText;

  /// No description provided for @descriptionTextHint.
  ///
  /// In en, this message translates to:
  /// **'Enter description text...'**
  String get descriptionTextHint;

  /// No description provided for @deleteDescription.
  ///
  /// In en, this message translates to:
  /// **'Delete description'**
  String get deleteDescription;

  /// No description provided for @deleteDescriptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this description?'**
  String get deleteDescriptionConfirm;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @defaultDescriptionCount.
  ///
  /// In en, this message translates to:
  /// **'Default number of descriptions selected:'**
  String get defaultDescriptionCount;

  /// No description provided for @currently.
  ///
  /// In en, this message translates to:
  /// **'Currently'**
  String get currently;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @selectAllDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllDescriptions;

  /// No description provided for @wineNotFound.
  ///
  /// In en, this message translates to:
  /// **'Wine not found'**
  String get wineNotFound;

  /// No description provided for @showDescriptions.
  ///
  /// In en, this message translates to:
  /// **'Show descriptions'**
  String get showDescriptions;

  /// No description provided for @frontLabel.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get frontLabel;

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @labelFront.
  ///
  /// In en, this message translates to:
  /// **'Label Front'**
  String get labelFront;

  /// No description provided for @labelBack.
  ///
  /// In en, this message translates to:
  /// **'Label Back'**
  String get labelBack;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @labelAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Wine label successfully analyzed!'**
  String get labelAnalyzed;

  /// No description provided for @descriptionsLoaded.
  ///
  /// In en, this message translates to:
  /// **'Descriptions successfully loaded'**
  String get descriptionsLoaded;

  /// No description provided for @winesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Wines updated'**
  String get winesUpdated;

  /// No description provided for @wineDeleted.
  ///
  /// In en, this message translates to:
  /// **'was deleted'**
  String get wineDeleted;

  /// No description provided for @wineImported.
  ///
  /// In en, this message translates to:
  /// **'Wine successfully imported'**
  String get wineImported;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsSaved;

  /// No description provided for @generatingSummaryAndPic.
  ///
  /// In en, this message translates to:
  /// **'Generating summary and visualization...'**
  String get generatingSummaryAndPic;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @selectImageSource.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @unnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamed;

  /// No description provided for @imported.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get imported;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @signinFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in - Please try again!'**
  String get signinFailed;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while analyzing your wine label - Please try again!'**
  String get analysisFailed;

  /// No description provided for @picMissing.
  ///
  /// In en, this message translates to:
  /// **'Please upload both label photos!'**
  String get picMissing;

  /// No description provided for @descriptionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Error while loading descriptions - Please try again!'**
  String get descriptionsLoadFailed;

  /// No description provided for @summaryGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Error while generating summary - Please try again!'**
  String get summaryGenerationFailed;

  /// No description provided for @urlOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Error opening URL - Please try again!'**
  String get urlOpenFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Error deleting wine - Please try again!'**
  String get deleteFailed;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Error importing wine - Please try again!'**
  String get importFailed;

  /// No description provided for @atLeastOneDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one description'**
  String get atLeastOneDescriptionRequired;

  /// No description provided for @noTextAvailable.
  ///
  /// In en, this message translates to:
  /// **'(No text available)'**
  String get noTextAvailable;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @analyzeLabel.
  ///
  /// In en, this message translates to:
  /// **'Analyze Label'**
  String get analyzeLabel;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
