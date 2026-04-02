import 'dart:convert';

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
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
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
}
