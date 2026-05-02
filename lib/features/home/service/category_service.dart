import 'package:html/parser.dart' as html_parser;
import 'package:mikomi/core/data/datasources/anilist_source.dart';
import 'package:mikomi/core/data/datasources/tencent_source.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';

class CategoryFilters {
  final String region;
  final String genre;
  final String year;
  final String status;

  const CategoryFilters({
    this.region = '全部',
    this.genre = '全部',
    this.year = '全部',
    this.status = '全部',
  });

  String get cacheKey => '$region|$genre|$year|$status';

  CategoryFilters copyWith({
    String? region,
    String? genre,
    String? year,
    String? status,
  }) {
    return CategoryFilters(
      region: region ?? this.region,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      status: status ?? this.status,
    );
  }
}

class CategoryService {
  final AniListSource _aniListSource;
  final TencentSource _tencentSource;

  static final Map<String, List<HomeAnimeModel>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, Future<List<HomeAnimeModel>>> _inFlight = {};

  static const Duration _cacheDuration = Duration(minutes: 10);

  static const List<String> regionOptions = ['全部', '内地', '日本', '韩国', '欧美'];

  static const List<String> genreOptions = [
    '全部',
    '动作',
    '冒险',
    '喜剧',
    '剧情',
    '奇幻',
    '恋爱',
    '科幻',
    '日常',
    '运动',
    '悬疑',
    '超自然',
  ];

  static const List<String> mainlandGenreOptions = [
    '全部',
    '玄幻',
    '科幻',
    '奇幻',
    '武侠',
    '仙侠',
    '都市',
    '恋爱',
    '搞笑',
    '冒险',
    '悬疑',
    '竞技',
    '日常',
    '真人',
    '治愈',
    '游戏',
    '异能',
    '历史',
    '古风',
    '智斗',
    '恐怖',
    '美食',
    '音乐',
    '其他',
  ];

  static List<String> yearOptions() {
    final now = DateTime.now().year;
    return ['全部', for (int y = now; y >= 2014; y--) '$y'];
  }

  static const List<String> statusOptions = ['全部', '连载中', '已完结'];

  CategoryService({AniListSource? aniListSource, TencentSource? tencentSource})
    : _aniListSource = aniListSource ?? AniListSource(),
      _tencentSource = tencentSource ?? TencentSource();

  Future<List<HomeAnimeModel>> fetchByFilters(
    CategoryFilters filters, {
    bool forceRefresh = false,
  }) async {
    final key = filters.cacheKey;

    if (!forceRefresh && _hasValidCache(key)) {
      return _cache[key] ?? const [];
    }

    final running = _inFlight[key];
    if (running != null) {
      return running;
    }

    final task = _loadByFilters(filters);
    _inFlight[key] = task;

    try {
      final result = await task;
      _cache[key] = result;
      _cacheTime[key] = DateTime.now();
      return result;
    } finally {
      _inFlight.remove(key);
    }
  }

  bool _hasValidCache(String key) {
    final data = _cache[key];
    final time = _cacheTime[key];
    if (data == null || time == null) {
      return false;
    }

    return DateTime.now().difference(time) < _cacheDuration;
  }

  Future<List<HomeAnimeModel>> _loadByFilters(CategoryFilters filters) async {
    if (filters.region == '内地') {
      return _loadMainlandByTencent(filters);
    }

    final mediaList = await _aniListSource.fetchMedia(
      page: 1,
      perPage: 72,
      sort: 'POPULARITY_DESC',
      country: _mapRegion(filters.region),
      genre: _mapGenre(filters.genre),
      seasonYear: _mapYear(filters.year),
      status: _mapStatus(filters.status),
    );

    return mediaList
        .whereType<Map<String, dynamic>>()
        .map(_mapAniListItem)
        .where((e) => e.id > 0 && e.coverUrl.isNotEmpty)
        .toList();
  }

  Future<List<HomeAnimeModel>> _loadMainlandByTencent(
    CategoryFilters filters,
  ) async {
    final scoreIndex = await _buildChineseScoreIndex();
    final html = await _tencentSource.fetchChineseRankHtml(limit: 120);
    final document = html_parser.parse(html);
    final cards = document.querySelectorAll('.list_item');

    final list = <HomeAnimeModel>[];

    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      final titleAnchor = card.querySelector('.figure_title');
      final coverAnchor = card.querySelector('a.figure');
      final image = card.querySelector('img.figure_pic');
      final desc = card.querySelector('.figure_desc');
      final caption = card.querySelector('.figure_caption');

      final title =
          titleAnchor?.attributes['title']?.trim() ??
          titleAnchor?.text.trim() ??
          coverAnchor?.attributes['title']?.trim() ??
          '';
      final cover = image?.attributes['src']?.trim() ?? '';
      final href =
          coverAnchor?.attributes['href']?.trim() ??
          titleAnchor?.attributes['href']?.trim() ??
          '';
      final summary =
          desc?.attributes['title']?.trim() ?? desc?.text.trim() ?? '';
      final captionText =
          caption?.attributes['title']?.trim() ?? caption?.text.trim() ?? '';
      final combined = '$title $summary $captionText';

      if (title.isEmpty || cover.isEmpty) {
        continue;
      }
      if (!_matchMainlandGenre(combined, filters.genre)) {
        continue;
      }
      if (!_matchMainlandYear(combined, filters.year)) {
        continue;
      }
      if (!_matchMainlandStatus(combined, filters.status)) {
        continue;
      }

      list.add(
        HomeAnimeModel(
          id: _stableId(href.isEmpty ? '$title-$i' : href),
          name: title,
          nameCn: title,
          summary: summary,
          airDate: _extractMainlandYear(combined),
          images: {
            'large': cover,
            'common': cover,
            'medium': cover,
            'small': cover,
            'grid': cover,
          },
          ratingScore: _resolveChineseScore(title, scoreIndex),
          ratingCount: 0,
          rank: 0,
          tags: const [HomeAnimeTag(name: '国漫', count: 0)],
          info: captionText,
        ),
      );
    }

    return list;
  }

  bool _matchMainlandGenre(String text, String genre) {
    if (genre == '全部' || genre == '其他') {
      return true;
    }

    final lower = text.toLowerCase();
    final keywords = switch (genre) {
      '玄幻' => ['玄幻', '修仙', '仙逆', '斗破', '神墓'],
      '科幻' => ['科幻', '机甲', '未来', '星际'],
      '奇幻' => ['奇幻', '魔法', '异世界'],
      '武侠' => ['武侠', '江湖'],
      '仙侠' => ['仙侠', '修真', '仙'],
      '都市' => ['都市', '现代'],
      '恋爱' => ['恋爱', '爱情'],
      '搞笑' => ['搞笑', '喜剧', '欢乐'],
      '冒险' => ['冒险', '历险', '探索'],
      '悬疑' => ['悬疑', '推理', '谜案'],
      '竞技' => ['竞技', '比赛', '运动'],
      '日常' => ['日常', '校园', '生活'],
      '真人' => ['真人', '真⼈', '特摄'],
      '治愈' => ['治愈', '温馨'],
      '游戏' => ['游戏', '电竞'],
      '异能' => ['异能', '超能力'],
      '历史' => ['历史', '古代'],
      '古风' => ['古风', '国风'],
      '智斗' => ['智斗', '谋略', '博弈'],
      '恐怖' => ['恐怖', '惊悚'],
      '美食' => ['美食', '料理'],
      '音乐' => ['音乐', '歌'],
      _ => <String>[],
    };

    for (final key in keywords) {
      if (lower.contains(key.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _matchMainlandYear(String text, String year) {
    if (year == '全部') {
      return true;
    }
    return text.contains(year);
  }

  bool _matchMainlandStatus(String text, String status) {
    if (status == '全部') {
      return true;
    }

    final finished = text.contains('完结') || (text.contains('全') && text.contains('集'));
    if (status == '已完结') {
      return finished;
    }
    if (status == '连载中') {
      return !finished;
    }
    return true;
  }

  String _extractMainlandYear(String text) {
    final match = RegExp(r'(20\d{2})').firstMatch(text);
    return match?.group(1) ?? '';
  }

  Future<Map<String, double>> _buildChineseScoreIndex() async {
    final mediaList = await _aniListSource.fetchMedia(
      page: 1,
      perPage: 120,
      sort: 'POPULARITY_DESC',
      country: 'CN',
    );

    final map = <String, double>{};
    for (final media in mediaList) {
      if (media is! Map<String, dynamic>) {
        continue;
      }

      final score100 = (media['averageScore'] as num?)?.toDouble() ?? 0;
      if (score100 <= 0) {
        continue;
      }

      final title = media['title'] as Map<String, dynamic>? ?? {};
      final score = (score100 / 10).clamp(0, 10).toDouble();
      final keys = [
        title['native']?.toString() ?? '',
        title['romaji']?.toString() ?? '',
        title['english']?.toString() ?? '',
      ];

      for (final key in keys) {
        final normalized = _normalizeTitle(key);
        if (normalized.isNotEmpty) {
          map[normalized] = score;
        }
      }
    }

    return map;
  }

  double _resolveChineseScore(String title, Map<String, double> scoreIndex) {
    return scoreIndex[_normalizeTitle(title)] ?? 0;
  }

  String _normalizeTitle(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[·•・:：\-—_!！?？,，.。/\\\(\)\[\]【】《》「」『』]'), '');
  }

  String? _mapRegion(String region) {
    return switch (region) {
      '日本' => 'JP',
      '韩国' => 'KR',
      '欧美' => 'US',
      _ => null,
    };
  }

  String? _mapGenre(String genreLabel) {
    return switch (genreLabel) {
      '动作' => 'Action',
      '冒险' => 'Adventure',
      '喜剧' => 'Comedy',
      '剧情' => 'Drama',
      '奇幻' => 'Fantasy',
      '恋爱' => 'Romance',
      '科幻' => 'Sci-Fi',
      '日常' => 'Slice of Life',
      '运动' => 'Sports',
      '悬疑' => 'Mystery',
      '超自然' => 'Supernatural',
      _ => null,
    };
  }

  int? _mapYear(String year) {
    if (year == '全部') {
      return null;
    }
    return int.tryParse(year);
  }

  String? _mapStatus(String status) {
    return switch (status) {
      '连载中' => 'RELEASING',
      '已完结' => 'FINISHED',
      _ => null,
    };
  }

  HomeAnimeModel _mapAniListItem(Map<String, dynamic> media) {
    final id = (media['id'] as num?)?.toInt() ?? 0;
    final titleMap = media['title'] as Map<String, dynamic>? ?? {};
    final coverMap = media['coverImage'] as Map<String, dynamic>? ?? {};
    final score100 = (media['averageScore'] as num?)?.toDouble() ?? 0;
    final popularity = (media['popularity'] as num?)?.toInt() ?? 0;
    final genres = (media['genres'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return HomeAnimeModel(
      id: id,
      name:
          titleMap['native']?.toString() ??
          titleMap['romaji']?.toString() ??
          titleMap['english']?.toString() ??
          '',
      nameCn: _isChineseTitle(titleMap['native']?.toString() ?? '')
          ? titleMap['native']?.toString() ?? ''
          : '',
      summary: genres.join(' / '),
      airDate: '',
      images: {
        'large': coverMap['large']?.toString() ?? '',
        'common': coverMap['medium']?.toString() ?? '',
        'medium': coverMap['medium']?.toString() ?? '',
        'small': coverMap['medium']?.toString() ?? '',
        'grid': coverMap['medium']?.toString() ?? '',
      },
      ratingScore: (score100 / 10).clamp(0, 10),
      ratingCount: popularity,
      rank: 0,
      tags: genres.map((g) => HomeAnimeTag(name: g, count: 0)).toList(),
      info: '',
    );
  }

  bool _isChineseTitle(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  int _stableId(String text) {
    var hash = 0;
    for (final codeUnit in text.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
