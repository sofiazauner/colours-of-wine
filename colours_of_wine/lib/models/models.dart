/* data-models */

import 'package:flutter/material.dart'; 
import 'package:colours_of_wine/models/exceptions.dart';


// structure for storing wines
class StoredWine {
  final String id;
  final String name;
  final List<String> descriptions;
  final DateTime? createdAt;

  StoredWine({
    required this.id, 
    required this.name,
    required this.descriptions,
    this.createdAt,});

   factory StoredWine.fromJson(Map<String, dynamic> json) {
    final rawList = json['descriptions'];
    final List<String> descriptions = rawList is List
        ? rawList.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
        : [];
    return StoredWine(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      descriptions: descriptions,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
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
