/* data model for wine description */

class WineDescription {
  final String id;
  final String source;            // name of source (z.B. "AproposWein", "falstaff")
  final String? url;              // optional URL
  final String text;              // complete text of description
  final bool isUsedForSummary;    // if used for summary
  final bool isExpanded;          // if description is expanded

  WineDescription({
    required this.id,
    required this.source,
    this.url,
    this.text = '',
    this.isUsedForSummary = false,
    this.isExpanded = false,
  });

  WineDescription copyWith({
    String? id,
    String? source,
    String? url,
    String? text,
    bool? isUsedForSummary,
    bool? isExpanded,
  }) {
    return WineDescription(
      id: id ?? this.id,
      source: source ?? this.source,
      url: url ?? this.url,
      text: text ?? this.text,
      isUsedForSummary: isUsedForSummary ?? this.isUsedForSummary,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  factory WineDescription.fromJson(Map<String, dynamic> json) {
    return WineDescription(
      id: json['id'] as String,
      source: json['source'] as String,
      url: json['url'] as String?,
      text: json['text'] as String? ?? '',
      isUsedForSummary: json['isUsedForSummary'] as bool? ?? false,
      isExpanded: json['isExpanded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'url': url,
      'text': text,
      'isUsedForSummary': isUsedForSummary,
      'isExpanded': isExpanded,
    };
  }
}
