class MyAnimeRefModel {
  final int bangumiId;
  final String bangumiName;
  final String bangumiNameCn;

  const MyAnimeRefModel({
    required this.bangumiId,
    required this.bangumiName,
    required this.bangumiNameCn,
  });

  String get displayName =>
      bangumiNameCn.isNotEmpty ? bangumiNameCn : bangumiName;

  String get title => displayName;

  Map<String, dynamic> toBaseJson() {
    return {
      'bangumiId': bangumiId,
      'bangumiName': bangumiName,
      'bangumiNameCn': bangumiNameCn,
    };
  }
}
