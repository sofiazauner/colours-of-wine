/* data model for wine */

import 'wine_description.dart';

enum WineCategory {
  meineWeine,
  importierteBeschreibungen,
  favoriten,
}

class Wine {
  final String id;
  final String name;
  final String year;
  final String producer;
  final String region;
  final String country;
  final WineCategory category;
  final String color;
  final String nose;
  final String palate;
  final String finish;
  final double alcohol;
  final double? restzucker;         // residual sugar in g/l
  final double? saure;              // acidity in g/l
  final String vinification;    
  final String foodPairing;
  final bool isFavorite;
  final String? fromImported;       // check if its from library or if user added the wine 
  final String? colorHex;           // hex color for visualization
  final String? imageUrl;           // URL or base64 encoded image
  final List<WineDescription> descriptions; // list of individual descriptions
  Wine({
    required this.id,
    required this.name,
    required this.year,
    required this.producer,
    required this.region,
    this.country = '',
    required this.category,
    required this.color,
    required this.nose,
    required this.palate,
    required this.finish,
    required this.alcohol,
    this.restzucker,
    this.saure,
    required this.vinification,
    required this.foodPairing,
    this.isFavorite = false,
    this.fromImported,
    this.colorHex,
    this.imageUrl,
    this.descriptions = const [],
  });

  Wine copyWith({
    String? id,
    String? name,
    String? year,
    String? producer,
    String? region,
    String? country,
    WineCategory? category,
    String? color,
    String? nose,
    String? palate,
    String? finish,
    double? alcohol,
    double? restzucker,
    double? saure,
    String? vinification,
    String? foodPairing,
    bool? isFavorite,
    String? fromImported,
    String? colorHex,
    String? imageUrl,
    List<WineDescription>? descriptions,
  }) {
    return Wine(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      producer: producer ?? this.producer,
      region: region ?? this.region,
      country: country ?? this.country,
      category: category ?? this.category,
      color: color ?? this.color,
      nose: nose ?? this.nose,
      palate: palate ?? this.palate,
      finish: finish ?? this.finish,
      alcohol: alcohol ?? this.alcohol,
      restzucker: restzucker ?? this.restzucker,
      saure: saure ?? this.saure,
      vinification: vinification ?? this.vinification,
      foodPairing: foodPairing ?? this.foodPairing,
      isFavorite: isFavorite ?? this.isFavorite,
      fromImported: fromImported ?? this.fromImported,
      colorHex: colorHex ?? this.colorHex,
      imageUrl: imageUrl ?? this.imageUrl,
      descriptions: descriptions ?? this.descriptions,
    );
  }

  String get displayName => '$name $year';
  String get fullName => '$producer | $name $year | $region';


  // convert json to wine object (used for db fetch, wine imports)
  factory Wine.fromJson(Map<String, dynamic> json) {
    List<WineDescription> descriptions = [];
    if (json['descriptions'] != null) {
      final descList = json['descriptions'] as List<dynamic>;
      if (descList.isNotEmpty) {
        if (descList.first is Map) {
          descriptions = descList
              .map((d) => WineDescription.fromJson(d as Map<String, dynamic>))
              .toList();
        } else {
          descriptions = descList.asMap().entries.map((entry) {
            return WineDescription(
              id: 'desc_${json['id']}_${entry.key}',
              source: 'Imported',
              text: entry.value.toString(),
            );
          }).toList();
        }
      }
    }
    return Wine(
      id: json['id'] as String? ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      year: json['year'] as String? ?? '',
      producer: json['producer'] as String? ?? '',
      region: json['region'] as String? ?? '',
      country: json['country'] as String? ?? '',
      category: json['category'] != null
          ? (WineCategory.values.firstWhere(
              (e) => e.name == json['category'],
              orElse: () => WineCategory.meineWeine,
            ))
          : WineCategory.meineWeine,
      color: json['color'] as String? ?? '',
      nose: json['nose'] as String? ?? '',
      palate: json['palate'] as String? ?? '',
      finish: json['finish'] as String? ?? '',
      alcohol: (json['alcohol'] as num?)?.toDouble() ?? 0.0,
      restzucker: json['restzucker'] != null ? (json['restzucker'] as num).toDouble() : null,
      saure: json['saure'] != null ? (json['saure'] as num).toDouble() : null,
      vinification: json['vinification'] as String? ?? '',
      foodPairing: json['foodPairing'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      fromImported: json['fromImported'] as String?,
      colorHex: json['colorHex'] as String?,
      imageUrl: json['imageUrl'] as String?,
      descriptions: descriptions,
    );
  }
  
  /// create query string for API calls
  String toUriComponent() {
    return Uri.encodeComponent("$name $producer $year $region $country");
  }

  /// convert from wineDescription format to backend description format
  Map<String, String> descriptionToMap(WineDescription desc) {
    return {
      'title': desc.source,
      'url': desc.url ?? '',
      'snippet': desc.text,
      'articleText': desc.text,
    };
  }
  
  /// convert from backend description format to WineDescription format
  static WineDescription descriptionFromMap(Map<String, String> descMap, {int index = 0}) {
    final text = descMap['articleText'] != "" && descMap['articleText'] != null ? descMap['articleText'] : descMap['snippet'];
    return WineDescription(
      id: 'desc_${DateTime.now().millisecondsSinceEpoch}_$index',
      source: descMap['title'] ?? 'Unknown',
      url: descMap['url'],
      text: text ?? '',
    );
  }

  /// convert wine object to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'producer': producer,
      'region': region,
      'country': country,
      'category': category.name,
      'color': color,
      'nose': nose,
      'palate': palate,
      'finish': finish,
      'alcohol': alcohol,
      'restzucker': restzucker,
      'saure': saure,
      'vinification': vinification,
      'foodPairing': foodPairing,
      'isFavorite': isFavorite,
      'fromImported': fromImported,
      'colorHex': colorHex,
      'imageUrl': imageUrl,
      'descriptions': descriptions.map((d) => d.toJson()).toList(),
    };
  }
}
