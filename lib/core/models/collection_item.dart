class CollectionItem {
  final int bangumiId;
  final String bangumiName;
  final String bangumiNameCn;
  final String coverUrl;
  final DateTime collectedAt;

  CollectionItem({
    required this.bangumiId,
    required this.bangumiName,
    required this.bangumiNameCn,
    required this.coverUrl,
    required this.collectedAt,
  });

  String get displayName =>
      bangumiNameCn.isNotEmpty ? bangumiNameCn : bangumiName;

  Map<String, dynamic> toJson() {
    return {
      'bangumiId': bangumiId,
      'bangumiName': bangumiName,
      'bangumiNameCn': bangumiNameCn,
      'coverUrl': coverUrl,
      'collectedAt': collectedAt.toIso8601String(),
    };
  }

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      bangumiId: json['bangumiId'] ?? 0,
      bangumiName: json['bangumiName'] ?? '',
      bangumiNameCn: json['bangumiNameCn'] ?? '',
      coverUrl: json['coverUrl'] ?? '',
      collectedAt: DateTime.parse(
        json['collectedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
