import 'package:dio/dio.dart';
import 'package:mikomi/core/models/danmaku.dart';
import 'package:mikomi/core/models/danmaku_search_response.dart';
import 'package:mikomi/core/models/danmaku_episode_response.dart';

class DanmakuService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.dandanplay.net',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'referer': 'https://www.dandanplay.com/',
      },
    ),
  );

  // 从Bangumi ID获取弹弹Play番剧ID
  Future<int> getDanDanBangumiIdByBgmId(int bgmBangumiId) async {
    try {
      final response = await _dio.get('/api/v2/bangumi/bgmtv/$bgmBangumiId');
      final data = DanmakuEpisodeResponse.fromJson(response.data);
      return data.bangumiId;
    } catch (e) {
      debugPrint('获取弹幕番剧ID失败: $e');
      return 0;
    }
  }

  // 从标题搜索番剧
  Future<DanmakuSearchResponse?> searchAnimeByTitle(String title) async {
    try {
      final response = await _dio.get(
        '/api/v2/search/anime',
        queryParameters: {'keyword': title},
      );
      return DanmakuSearchResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('搜索弹幕番剧失败: $e');
      return null;
    }
  }

  // 从标题获取番剧ID（使用相似度匹配）
  Future<int> getBangumiIdByTitle(String title) async {
    final searchResponse = await searchAnimeByTitle(title);
    if (searchResponse == null || searchResponse.animes.isEmpty) {
      return 0;
    }

    int bestAnimeId = 0;
    double maxSimilarity = 0;

    for (var anime in searchResponse.animes) {
      int animeId = anime.animeId;
      // 过滤无效ID
      if (animeId >= 100000 || animeId < 2) {
        continue;
      }

      String animeTitle = anime.animeTitle;
      double similarity = _calculateSimilarity(animeTitle, title);

      // 完全匹配
      if (similarity == 1) {
        debugPrint('弹幕: 完全匹配 $title');
        return animeId;
      }

      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        bestAnimeId = animeId;
        debugPrint('弹幕: 匹配 $title --- $animeTitle 相似度: $similarity');
      }
    }

    return bestAnimeId;
  }

  // 获取番剧的分集信息
  Future<DanmakuEpisodeResponse> getEpisodesByBangumiId(int bangumiId) async {
    try {
      final response = await _dio.get('/api/v2/bangumi/$bangumiId');
      return DanmakuEpisodeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('获取弹幕分集信息失败: $e');
      return DanmakuEpisodeResponse.empty();
    }
  }

  // 获取指定集数的弹幕
  Future<List<Danmaku>> getDanmakuByEpisode(int bangumiId, int episode) async {
    if (bangumiId == 0) {
      return [];
    }

    try {
      // 弹弹Play的分集ID规则：番剧ID + 集数（4位补零）
      // 例如：番剧ID 1758，第1集 = 17580001
      final episodeId = int.parse(
        '$bangumiId${episode.toString().padLeft(4, '0')}',
      );

      final response = await _dio.get(
        '/api/v2/comment/$episodeId',
        queryParameters: {'withRelated': 'true'},
      );

      final List<dynamic> comments = response.data['comments'];
      return comments.map((comment) => Danmaku.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('获取弹幕失败: $e');
      return [];
    }
  }

  // 通过分集ID直接获取弹幕
  Future<List<Danmaku>> getDanmakuByEpisodeId(int episodeId) async {
    try {
      final response = await _dio.get(
        '/api/v2/comment/$episodeId',
        queryParameters: {'withRelated': 'true'},
      );

      final List<dynamic> comments = response.data['comments'];
      return comments.map((comment) => Danmaku.fromJson(comment)).toList();
    } catch (e) {
      debugPrint('获取弹幕失败: $e');
      return [];
    }
  }

  // 简单的字符串相似度计算（Levenshtein距离）
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final len1 = s1.length;
    final len2 = s2.length;
    final maxLen = len1 > len2 ? len1 : len2;

    // 简化版：检查包含关系
    if (s1.toLowerCase().contains(s2.toLowerCase()) ||
        s2.toLowerCase().contains(s1.toLowerCase())) {
      return 0.8;
    }

    // 计算Levenshtein距离
    List<List<int>> dp = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (int i = 0; i <= len1; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = [
            dp[i - 1][j] + 1,
            dp[i][j - 1] + 1,
            dp[i - 1][j - 1] + 1,
          ].reduce((a, b) => a < b ? a : b);
        }
      }
    }

    return 1.0 - (dp[len1][len2] / maxLen);
  }
}

void debugPrint(String message) {
  print(message);
}
