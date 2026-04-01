import 'package:mikomi/features/my/models/my_anime_ref_model.dart';

class CollectionModel extends MyAnimeRefModel {
  final String coverUrl;
  final DateTime collectedAt;

  CollectionModel({
    required super.bangumiId,
    required super.bangumiName,
    required super.bangumiNameCn,
    required this.coverUrl,
    required this.collectedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      ...toBaseJson(),
      'coverUrl': coverUrl,
      'collectedAt': collectedAt.toIso8601String(),
    };
  }

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
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
