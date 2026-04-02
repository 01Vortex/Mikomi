import 'package:flutter/foundation.dart';
import 'package:mikomi/core/data/datasources/dandanplay.dart';
import 'package:mikomi/features/video/models/danmaku_episode_response.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';
import 'package:mikomi/features/video/models/danmaku_search_response.dart';

class DanmakuRepository {
  final DanDanPlaySource _source;

  DanmakuRepository({DanDanPlaySource? source})
    : _source = source ?? DanDanPlaySource();

  Future<int> getDanDanBangumiIdByBgmId(int bgmBangumiId) async {
    try {
      final data = await _source.fetchBangumiByBgmId(bgmBangumiId);
      if (data == null) return 0;
      return DanmakuEpisodeResponse.fromJson(data).bangumiId;
    } catch (e) {
      debugPrint('获取弹幕番剧ID失败: $e');
      return 0;
    }
  }

  Future<DanmakuSearchResponse?> searchAnimeByTitle(String title) async {
    try {
      final data = await _source.searchAnime(title);
      if (data == null) return null;
      return DanmakuSearchResponse.fromJson(data);
    } catch (e) {
      debugPrint('搜索弹幕番剧失败: $e');
      return null;
    }
  }

  Future<int> getBangumiIdByTitle(String title) async {
    final searchResponse = await searchAnimeByTitle(title);
    if (searchResponse == null || searchResponse.animes.isEmpty) {
      return 0;
    }

    var bestAnimeId = 0;
    var maxSimilarity = 0.0;

    for (var anime in searchResponse.animes) {
      final animeId = anime.animeId;
      if (animeId >= 100000 || animeId < 2) continue;

      final similarity = _calculateSimilarity(anime.animeTitle, title);
      if (similarity == 1) return animeId;

      if (similarity > maxSimilarity) {
        maxSimilarity = similarity;
        bestAnimeId = animeId;
      }
    }

    return bestAnimeId;
  }

  Future<DanmakuEpisodeResponse> getEpisodesByBangumiId(int bangumiId) async {
    try {
      final data = await _source.fetchBangumiEpisodes(bangumiId);
      if (data == null) return DanmakuEpisodeResponse.empty();
      return DanmakuEpisodeResponse.fromJson(data);
    } catch (e) {
      debugPrint('获取弹幕分集信息失败: $e');
      return DanmakuEpisodeResponse.empty();
    }
  }

  Future<List<Danmaku>> getDanmakuByEpisode(int bangumiId, int episode) async {
    if (bangumiId == 0) return [];

    final episodeId = await _resolveEpisodeId(bangumiId, episode);
    if (episodeId > 0) {
      final comments = await getDanmakuByEpisodeId(episodeId);
      if (comments.isNotEmpty) return comments;
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

  Future<List<Danmaku>> getDanmakuByEpisodeId(int episodeId) async {
    try {
      final comments = await _source.fetchCommentsByEpisodeId(episodeId);
      return comments
          .map((comment) => Danmaku.fromJson(comment as Map<String, dynamic>))
          .toList();
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
      if (number == episode) return item.episodeId;
    }

    return 0;
  }

  int? _extractEpisodeNumber(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
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

    for (var i = 0; i <= len1; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
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
