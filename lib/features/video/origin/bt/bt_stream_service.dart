import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// BT 流服务——将 magnet 链接转换为 HTTP 流 URL，供 media_kit 播放。
///
/// 使用 webtor.io 公共网关作为后端：
/// 1. 从 magnet 提取 info_hash
/// 2. 通过 webtor.io API 获取文件列表
/// 3. 返回最大视频文件的直接流 URL
class BtStreamService {
  final Dio _dio;

  BtStreamService({Dio? dio})
    : _dio = dio ??
          Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ));

  /// 检查 webtor.io 是否已缓存该种子，是则返回流 URL。
  /// 返回 null 表示不可用（需跳过或回退）。
  Future<String?> resolveStreamUrl(String magnetLink) async {
    final infoHash = _extractInfoHash(magnetLink);
    if (infoHash == null) {
      debugPrint('BtStreamService: 无法从 magnet 提取 info_hash');
      return null;
    }

    try {
      // 获取 torrent 文件列表
      final files = await _fetchTorrentFiles(infoHash);
      if (files.isEmpty) {
        debugPrint('BtStreamService: torrent 无文件');
        return null;
      }

      // 选择最大的视频文件
      final videoIndex = _pickVideoFile(files);
      if (videoIndex < 0) {
        debugPrint('BtStreamService: 未找到视频文件');
        return null;
      }

      final streamUrl =
          'https://webtor.io/api/v1/torrent/$infoHash/files/$videoIndex/stream';
      debugPrint('BtStreamService: 流 URL → $streamUrl');
      return streamUrl;
    } catch (e) {
      debugPrint('BtStreamService: 转换失败 - $e');
      return null;
    }
  }

  /// 提取 info_hash（magnet:?xt=urn:btih:XXX → XXX）
  static String? _extractInfoHash(String magnet) {
    final match = RegExp(
      r'btih:([0-9a-fA-F]{40})',
      caseSensitive: false,
    ).firstMatch(magnet);
    if (match != null) return match.group(1)!.toLowerCase();

    // 尝试 Base32 编码的 info hash
    final b32Match = RegExp(
      r'btih:([0-9a-zA-Z]{32})',
      caseSensitive: false,
    ).firstMatch(magnet);
    return b32Match?.group(1);
  }

  /// 获取 torrent 的文件列表
  Future<List<_TorrentFile>> _fetchTorrentFiles(String infoHash) async {
    try {
      final response = await _dio.get(
        'https://webtor.io/api/v1/torrent/$infoHash',
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data as Map<String, dynamic>;
      final files = (data['files'] as List<dynamic>?) ?? const [];
      return files
          .whereType<Map<String, dynamic>>()
          .map((f) => _TorrentFile(
                name: (f['name'] as String?) ?? '',
                size: (f['size'] as num?)?.toInt() ?? 0,
              ))
          .toList();
    } catch (e) {
      debugPrint('BtStreamService: 获取文件列表失败 - $e');
      return [];
    }
  }

  /// 选择最大的视频文件索引
  int _pickVideoFile(List<_TorrentFile> files) {
    final videoExts = {
      '.mp4', '.mkv', '.avi', '.mov', '.webm',
      '.flv', '.wmv', '.m4v', '.mpg', '.mpeg',
    };

    int bestIndex = -1;
    int bestSize = 0;

    for (int i = 0; i < files.length; i++) {
      final ext = files[i].name.toLowerCase();
      final isVideo = videoExts.any((e) => ext.endsWith(e));
      if (isVideo && files[i].size > bestSize) {
        bestSize = files[i].size;
        bestIndex = i;
      }
    }

    // 如果没找到视频，返回最大的文件
    if (bestIndex < 0 && files.isNotEmpty) {
      int maxIdx = 0;
      int maxSz = files[0].size;
      for (int i = 1; i < files.length; i++) {
        if (files[i].size > maxSz) {
          maxSz = files[i].size;
          maxIdx = i;
        }
      }
      bestIndex = maxIdx;
    }

    return bestIndex;
  }
}

class _TorrentFile {
  final String name;
  final int size;
  const _TorrentFile({required this.name, required this.size});
}
