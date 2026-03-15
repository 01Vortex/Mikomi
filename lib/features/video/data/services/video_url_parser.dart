import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class VideoUrlParser {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// 从网页中提取视频播放地址
  Future<String?> parseVideoUrl(String pageUrl) async {
    try {
      debugPrint('开始解析视频地址: $pageUrl');

      final response = await _dio.get(
        pageUrl,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          },
        ),
      );

      if (response.statusCode == 200) {
        final htmlString = response.data.toString();
        debugPrint('获取到HTML，长度: ${htmlString.length}');

        // 尝试多种正则表达式提取视频地址
        final patterns = [
          // m3u8格式
          RegExp(r'https?://[^\s"' + "'" + r'<>]+\.m3u8[^\s"' + "'" + r'<>]*'),
          // mp4格式
          RegExp(r'https?://[^\s"' + "'" + r'<>]+\.mp4[^\s"' + "'" + r'<>]*'),
          // 通用视频URL模式
          RegExp(
            r'https?://[^\s"' +
                "'" +
                r'<>]+/[^\s"' +
                "'" +
                r'<>]*\.(m3u8|mp4|flv|avi|mkv)',
          ),
          // URL编码的视频地址
          RegExp(r'url=([^&\s"' + "'" + r'<>]+\.(?:m3u8|mp4))'),
        ];

        for (final pattern in patterns) {
          final match = pattern.firstMatch(htmlString);
          if (match != null) {
            String videoUrl = match.group(0) ?? match.group(1) ?? '';

            // 如果是URL编码的，需要解码
            if (videoUrl.contains('%')) {
              videoUrl = Uri.decodeFull(videoUrl);
            }

            debugPrint('找到视频地址: $videoUrl');
            return videoUrl;
          }
        }

        // 尝试查找iframe中的视频源
        final iframePattern = RegExp(
          r'<iframe[^>]+src=["' + "'" + r']([^"' + "'" + r']+)["' + "'" + r']',
        );
        final iframeMatch = iframePattern.firstMatch(htmlString);
        if (iframeMatch != null) {
          String iframeSrc = iframeMatch.group(1) ?? '';
          debugPrint('找到iframe: $iframeSrc');

          // 如果iframe是相对路径，转换为绝对路径
          if (!iframeSrc.startsWith('http')) {
            final uri = Uri.parse(pageUrl);
            if (iframeSrc.startsWith('/')) {
              iframeSrc = '${uri.scheme}://${uri.host}$iframeSrc';
            } else {
              final path = uri.path.substring(0, uri.path.lastIndexOf('/') + 1);
              iframeSrc = '${uri.scheme}://${uri.host}$path$iframeSrc';
            }
          }

          // 递归解析iframe
          return await parseVideoUrl(iframeSrc);
        }

        debugPrint('未找到视频地址');
      }

      return null;
    } catch (e) {
      debugPrint('解析视频地址失败: $e');
      return null;
    }
  }
}
