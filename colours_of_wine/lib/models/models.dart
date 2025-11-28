/* data-models */

import 'package:flutter/material.dart'; 


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
  final String winery;           // Weingut
  final String vintage;          // Jahrgang
  final String grapeVariety;     // Rebsorte
  final String vineyardLocation; // Anbaugebiet
  final String country;

  final allowedDomains = [       // filter descriptions form Internet and only allow trusted wine sites for web search
      "winefolly.com",           // (TODO: put in backend!)
      "decanter.com",
      "wineenthusiast.com",
      "wine.com",
      "vivino.com",
      "wine-searcher.com",
      "jancisrobinson.com",
      "vinous.com",
      "jamessuckling.com",
      "winespectator.com",
      "falstaff.de",
      "wein.plus",
      "cellartracker.com",
      "vicampo.de"
      ];

  String toUriComponent() {      // encode the wine as a URI component
    final name = this.name;
    final weingut = this.winery;
    final jahrgang = this.vintage;
    final rebsorte = this.grapeVariety;
    final anbaugebiet = this.vineyardLocation;
    final land = this.country;

    final siteFilter = allowedDomains.map((d) => "site:$d").join(" OR ");
    
    return Uri.encodeComponent("$name $weingut $jahrgang $rebsorte $anbaugebiet $land wine description ($siteFilter)");
  }
}