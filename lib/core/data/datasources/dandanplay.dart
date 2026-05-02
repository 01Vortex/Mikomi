import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class DanDanPlaySource {
  static const String _dandanAppId = 'kvpx7qkqjh';
  static const String _dandanSecret = 'rABUaBLqdz7aCSi3fe88ZDj2gwga9Vax';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.dandanplay.net',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'user-agent': _randomUserAgent(),
        'referer': '',
      },
    ),
  );

  DanDanPlaySource() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final signature = _generateSignature(options.path, timestamp);

          options.headers.addAll({
            'user-agent': _randomUserAgent(),
            'referer': '',
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

  static String _randomUserAgent() {
    const userAgents = [
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36',
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15',
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36',
    ];
    return userAgents[Random().nextInt(userAgents.length)];
  }

  String _generateSignature(String path, int timestamp) {
    final data = '$_dandanAppId$timestamp$path$_dandanSecret';
    final digest = sha256.convert(utf8.encode(data));
    return base64Encode(digest.bytes);
  }

  Future<Map<String, dynamic>?> fetchBangumiByBgmId(int bgmBangumiId) async {
    final response = await _dio.get('/api/v2/bangumi/bgmtv/$bgmBangumiId');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
  }

  Future<Map<String, dynamic>?> searchAnime(String keyword) async {
    final response = await _dio.get(
      '/api/v2/search/anime',
      queryParameters: {'keyword': keyword},
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
  }

  Future<Map<String, dynamic>?> fetchBangumiEpisodes(int bangumiId) async {
    final response = await _dio.get('/api/v2/bangumi/$bangumiId');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : null;
  }

  Future<List<dynamic>> fetchCommentsByEpisodeId(int episodeId) async {
    final response = await _dio.get(
      '/api/v2/comment/$episodeId',
      queryParameters: {'withRelated': 'true'},
    );
    return (response.data['comments'] as List?) ?? [];
  }

  Future<int?> resolveEpisodeIdByBgmBangumiId(
    int bgmBangumiId,
    int episode,
  ) async {
    final bangumiData = await fetchBangumiByBgmId(bgmBangumiId);
    return _resolveEpisodeIdFromBangumiData(bangumiData, episode);
  }

  Future<int?> resolveEpisodeIdByBangumiId(int bangumiId, int episode) async {
    final bangumiData = await fetchBangumiEpisodes(bangumiId);
    return _resolveEpisodeIdFromBangumiData(bangumiData, episode);
  }

  Future<int?> resolveEpisodeId({
    required int? bgmBangumiId,
    required String? animeTitle,
    required int episode,
  }) async {
    if (bgmBangumiId != null) {
      try {
        final episodeId = await resolveEpisodeIdByBgmBangumiId(
          bgmBangumiId,
          episode,
        );
        if (episodeId != null) return episodeId;
      } catch (_) {}
    }

    if (animeTitle != null && animeTitle.trim().isNotEmpty) {
      try {
        final danDanBangumiId = await resolveBangumiIdByTitle(animeTitle);
        if (danDanBangumiId != null) {
          return resolveEpisodeIdByBangumiId(danDanBangumiId, episode);
        }
      } catch (_) {}
    }

    return null;
  }

  int? _resolveEpisodeIdFromBangumiData(
    Map<String, dynamic>? bangumiData,
    int episode,
  ) {
    final bangumi = bangumiData?['bangumi'];
    final episodeList = bangumi is Map<String, dynamic>
        ? (bangumi['episodes'] as List?) ?? const []
        : (bangumiData?['episodes'] as List?) ?? const [];

    for (final item in episodeList) {
      if (item is! Map) continue;
      final episodeNumber = item['episodeNumber'];
      final episodeId = item['episodeId'];
      final normalizedEpisodeNumber = int.tryParse('$episodeNumber');
      if (normalizedEpisodeNumber == episode && episodeId is num) {
        return episodeId.toInt();
      }
    }

    return null;
  }

  Future<int?> resolveBangumiIdByTitle(String title) async {
    final searchResult = await searchAnime(title);
    final animeList = (searchResult?['animes'] as List?) ?? const [];

    for (final item in animeList) {
      if (item is! Map) continue;
      final bangumiId = item['animeId'];
      if (bangumiId is num) {
        return bangumiId.toInt();
      }
    }

    return null;
  }
}
