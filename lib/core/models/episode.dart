class Episode {
  final int number;
  final String? title;
  final String? url;

  Episode({required this.number, this.title, this.url});

  factory Episode.fromRoadData({
    required int index,
    required String identifier,
    required String url,
  }) {
    // 尝试从标题中提取集数编号，如"第1集"、"01"、"EP01"等
    final number = _extractEpisodeNumber(identifier) ?? (index + 1);
    return Episode(number: number, title: identifier, url: url);
  }

  /// 从集数标题中提取数字，提取不到则返回 null
  static int? _extractEpisodeNumber(String identifier) {
    // 匹配纯数字或带前缀的数字，如 "01"、"第1集"、"EP01"、"第01话" 等
    final match = RegExp(r'(\d+)').firstMatch(identifier);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
