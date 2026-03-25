import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:mikomi/core/models/danmaku.dart';
import 'package:mikomi/core/models/danmaku_search_response.dart';
import 'package:mikomi/core/models/danmaku_episode_response.dart';

class DanmakuService {
  static const String _dandanAppId = 'kvpx7qkqjh';
  static const String _dandanSecret = 'rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.dandanplay.net',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'referer': '',
      },
    ),
  );

  DanmakuService() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final path = options.path;
          final signature = _generateDandanSignature(path, timestamp);

          options.headers.addAll({
            'X-Auth': 1,
            'X-AppId': _dandanAppId,
            'X-Timestamp': timestamp,
            'X-Signature': signature,
          });

          handler.next(options);
        },
      ),
    );
  }

  String _generateDandanSignature(String path, int timestamp) {
    final data = '$_dandanAppId$timestamp$path$_dandanSecret';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64Encode(digest.bytes);
  }

  /// 从 Bangumi ID 获取弹弹Play番剧ID
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

  /// 从标题搜索番剧
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

  /// 从标题获取番剧ID（使用相似度匹配）
  Future<int> getBangumiIdByTitle(String title) async {
    final searchResponse = await searchAnimeByTitle(title);
    if (searchResponse == null || searchResponse.animes.isEmpty) {
      return 0;
    }

    int bestAnimeId = 0;
    double maxSimilarity = 0;

    for (var anime in searchResponse.animes) {
      final animeId = anime.animeId;
      if (animeId >= 100000 || animeId < 2) {
        continue;
      }

      final animeTitle = anime.animeTitle;
      final similarity = _calculateSimilarity(animeTitle, title);

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

  /// 获取番剧的分集信息
  Future<DanmakuEpisodeResponse> getEpisodesByBangumiId(int bangumiId) async {
    try {
      final response = await _dio.get('/api/v2/bangumi/$bangumiId');
      return DanmakuEpisodeResponse.fromJson(response.data);
    } catch (e) {
      debugPrint('获取弹幕分集信息失败: $e');
      return DanmakuEpisodeResponse.empty();
    }
  }

  /// 获取指定集数的弹幕（优先用真实 episodeId）
  Future<List<Danmaku>> getDanmakuByEpisode(int bangumiId, int episode) async {
    if (bangumiId == 0) return [];

    final episodeId = await _resolveEpisodeId(bangumiId, episode);
    if (episodeId > 0) {
      final comments = await getDanmakuByEpisodeId(episodeId);
      if (comments.isNotEmpty) {
        return comments;
      }
    }

    try {
      final legacyEpisodeId = int.parse(
        '$bangumiId${episode.toString().padLeft(4, '0')}',
      );
      return await getDanmakuByEpisodeId(legacyEpisodeId);
    } catch (e) {
      debugPrint('获取弹幕失败: $e');
      return [];
    }
  }

  Future<int> _resolveEpisodeId(int bangumiId, int episode) async {
    final response = await getEpisodesByBangumiId(bangumiId);
    if (response.episodes.isEmpty) return 0;

    if (episode > 0 && episode <= response.episodes.length) {
      return response.episodes[episode - 1].episodeId;
    }

    for (final item in response.episodes) {
      final number = _extractEpisodeNumber(item.episodeTitle);
      if (number == episode) {
        return item.episodeId;
      }
    }

    return 0;
  }

  int? _extractEpisodeNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  /// 通过分集ID直接获取弹幕
  Future<List<Danmaku>> getDanmakuByEpisodeId(int episodeId) async {
    try {
      final response = await _dio.get(
        '/api/v2/comment/$episodeId',
        queryParameters: {'withRelated': 'true'},
      );

      final comments = (response.data['comments'] as List?) ?? [];
      return comments
          .map((comment) => Danmaku.fromJson(comment as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('获取弹幕失败: $e');
      return [];
    }
  }

  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final len1 = s1.length;
    final len2 = s2.length;
    final maxLen = len1 > len2 ? len1 : len2;

    if (s1.toLowerCase().contains(s2.toLowerCase()) ||
        s2.toLowerCase().contains(s1.toLowerCase())) {
      return 0.8;
    }

    final dp = List.generate(len1 + 1, (_) => List.filled(len2 + 1, 0));

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
