/* data-models */

import 'package:flutter/material.dart'; 


// structure for storing wines
class StoredWine {
  final String id;
  final String name;
  final List<String> descriptions;

  // persisted visualization and summary
  final String summary;
  final bool approved;
  final String? image; // base64 jpeg (200x200) or null if not generated yet

  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoredWine({
    required this.id, 
    required this.name,
    required this.descriptions,
    this.summary = "",
    this.approved = false,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory StoredWine.fromJson(Map<String, dynamic> json) {
    final rawList = json['descriptions'];
    final List<String> descriptions = rawList is List
        ? rawList.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
        : [];
    return StoredWine(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      descriptions: descriptions,
      summary: (json['summary'] ?? '').toString(),
      approved: json['approved'] == true,
      image: json['image'] is String ? json['image'] as String : null,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : null,
    );
  }
}


// web search result structure
class WineWebResult {
  final String summary;
  final bool approved;
  final Image image;

  WineWebResult(
    this.summary,
    this.approved,
    this.image
  );
}


// wine data structure
class WineData {
  WineData(Map<String, String> data) :
    name = data['Name'] ?? '',
    winery = data['Winery'] ?? '',
    vintage = data['Vintage'] ?? '',
    grapeVariety = data['Grape Variety'] ?? '',
    vineyardLocation = data['Vineyard Location'] ?? '',
    country = data['Country'] ?? '';

  Map<String, String> toMap() {
    return {
      'Name': name,
      'Winery': winery,
      'Vintage': vintage,
      'Grape Variety': grapeVariety,
      'Vineyard Location': vineyardLocation,
      'Country': country
    };
  }

  final String name;
  final String winery;           
  final String vintage;         
  final String grapeVariety;     
  final String vineyardLocation; 
  final String country;

  String toUriComponent() {      // encode the wine as a URI component
    final name = this.name;
    final weingut = this.winery;
    final jahrgang = this.vintage;
    final rebsorte = this.grapeVariety;
    final anbaugebiet = this.vineyardLocation;
    final land = this.country;
    
    return Uri.encodeComponent("$name $weingut $jahrgang $rebsorte $anbaugebiet $land");
  }
}
