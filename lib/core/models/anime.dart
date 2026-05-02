class Anime {
  final int id;
  final String name;
  final String nameCn;
  final String summary;
  final String airDate;
  final Map<String, String> images;
  final double ratingScore;
  final int ratingCount;
  final int rank;
  final List<BangumiTag> tags;
  final String info;

  Anime({
    required this.id,
    required this.name,
    required this.nameCn,
    required this.summary,
    required this.airDate,
    required this.images,
    required this.ratingScore,
    required this.ratingCount,
    required this.rank,
    this.tags = const [],
    this.info = '',
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] ?? {};
    final subject = json['subject'] ?? json;

    // 解析标签
    final List<BangumiTag> tagsList = [];
    if (subject['tags'] != null) {
      final tags = subject['tags'];
      if (tags is List) {
        for (var tag in tags) {
          try {
            if (tag is Map) {
              tagsList.add(BangumiTag.fromJson(Map<String, dynamic>.from(tag)));
            }
          } catch (e) {
            // 忽略解析失败的标签
          }
        }
      }
    }

    final originalName = _stringValue(subject, const ['name']);
    final chineseName = _extractChineseName(subject, fallbackOriginal: originalName);

    return Anime(
      id: subject['id'] ?? 0,
      name: originalName,
      nameCn: chineseName,
      summary: subject['summary'] ?? '',
      airDate: subject['date'] ?? '',
      images: Map<String, String>.from(
        subject['images'] ??
            {'large': '', 'common': '', 'medium': '', 'small': '', 'grid': ''},
      ),
      ratingScore: (rating['score'] ?? 0.0).toDouble(),
      ratingCount: rating['total'] ?? 0,
      rank: rating['rank'] ?? 0,
      tags: tagsList,
      info: subject['info'] ?? '',
    );
  }

  String get displayName => _isChineseText(nameCn) ? nameCn : name;

  String get chineseSummary => _extractChineseSummary(summary);

  String get coverUrl =>
      images['large'] ??
      images['common'] ??
      images['medium'] ??
      images['small'] ??
      images['grid'] ??
      '';

  // 添加copyWith方法用于数据迁移
  Anime copyWith({
    int? id,
    String? name,
    String? nameCn,
    String? summary,
    String? airDate,
    Map<String, String>? images,
    double? ratingScore,
    int? ratingCount,
    int? rank,
    List<BangumiTag>? tags,
    String? info,
  }) {
    return Anime(
      id: id ?? this.id,
      name: name ?? this.name,
      nameCn: nameCn ?? this.nameCn,
      summary: summary ?? this.summary,
      airDate: airDate ?? this.airDate,
      images: images ?? this.images,
      ratingScore: ratingScore ?? this.ratingScore,
      ratingCount: ratingCount ?? this.ratingCount,
      rank: rank ?? this.rank,
      tags: tags ?? this.tags,
      info: info ?? this.info,
    );
  }
}

bool _isChineseText(String text) {
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
}

String _stringValue(Map<dynamic, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

String _extractChineseName(
  Map<dynamic, dynamic> subject, {
  required String fallbackOriginal,
}) {
  final direct = _stringValue(subject, const [
    'name_cn',
    'nameCn',
    'nameCN',
    'chineseName',
    'titleCn',
    'title_cn',
  ]);
  if (_isChineseText(direct)) return direct;

  final nameCnObject = subject['name_cn'];
  if (nameCnObject is Map) {
    final value = _stringValue(nameCnObject, const [
      'cn',
      'zh',
      'zh_cn',
      'zh-Hans',
      'zh_hans',
      'value',
    ]);
    if (_isChineseText(value)) return value;
  }

  final infoboxValue = _extractChineseNameFromInfobox(subject['infobox']);
  if (_isChineseText(infoboxValue)) return infoboxValue;

  final aliases = subject['aliases'] ?? subject['alias'];
  if (aliases is List) {
    for (final alias in aliases) {
      final value = alias?.toString().trim() ?? '';
      if (_isChineseText(value)) return value;
    }
  }

  return _isChineseText(fallbackOriginal) ? fallbackOriginal : '';
}

String _extractChineseNameFromInfobox(dynamic infobox) {
  if (infobox is! List) return '';

  for (final item in infobox) {
    if (item is! Map) continue;
    final key = (item['key'] ?? item['name'] ?? '').toString();
    if (!key.contains('中文') && !key.contains('简体')) continue;

    final value = item['value'];
    if (value is String && _isChineseText(value)) return value.trim();
    if (value is List) {
      for (final entry in value) {
        final text = entry?.toString().trim() ?? '';
        if (_isChineseText(text)) return text;
      }
    }
  }

  return '';
}

String _extractChineseSummary(String text) {
  final normalized = text.replaceAll('\r\n', '\n').trim();
  if (normalized.isEmpty) return '';

  final blocks = normalized
      .split(RegExp(r'\n{2,}|(?=\[简体中文\])|(?=\[中文\])|(?=简体中文[:：])|(?=中文[:：])'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final explicitChinese = blocks.where((block) {
    final lower = block.toLowerCase();
    return block.contains('中文') ||
        block.contains('简体') ||
        lower.contains('chinese') ||
        lower.contains('zh-cn');
  }).toList();

  final candidates = explicitChinese.isNotEmpty ? explicitChinese : blocks;
  String best = '';
  var bestScore = -1.0;

  for (final block in candidates) {
    final score = _chineseRatio(block);
    if (score > bestScore) {
      bestScore = score;
      best = block;
    }
  }

  if (!_isChineseText(best)) return '';
  return best
      .replaceAll(RegExp(r'^\[(简体中文|中文|zh-cn|chinese)\]\s*', caseSensitive: false), '')
      .replaceAll(RegExp(r'^(简体中文|中文|zh-cn|chinese)[:：]\s*', caseSensitive: false), '')
      .trim();
}

double _chineseRatio(String text) {
  final visible = text.replaceAll(RegExp(r'\s+'), '');
  if (visible.isEmpty) return 0;
  final chineseCount = RegExp(r'[\u4e00-\u9fff]').allMatches(visible).length;
  return chineseCount / visible.length;
}

class BangumiTag {
  final String name;
  final int count;

  BangumiTag({required this.name, required this.count});

  factory BangumiTag.fromJson(Map<String, dynamic> json) {
    return BangumiTag(name: json['name'] ?? '', count: json['count'] ?? 0);
  }
}
