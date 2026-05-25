import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';

/// 视频流解析器接口——Web 爬虫、BT、本地等不同来源实现各自的解析逻辑。
///
/// 当前实现：
/// - [WebSourceResolver]（Web 爬虫，WebView + XPath/JS）
///
/// 未来扩展：
/// - `BtSourceResolver`（BitTorrent，magnet → DHT/tracker → stream）
/// - `LocalSourceResolver`（本地文件）
abstract class VideoSourceResolver {
  /// 解析指定剧集的视频流 URL（支持 .mp4 / .m3u8 / 本地代理 URL）
  Future<String> resolveStreamUrl({
    required VideoSource source,
    required Episode episode,
  });

  /// 静默刷新——已有缓存时尝试获取新 URL，仅当新旧 URL 不同时返回新值。
  /// 返回 null 表示无需更新（相同 URL 或解析失败）。
  Future<String?> refreshStreamUrl({
    required VideoSource source,
    required Episode episode,
    required String lastResolvedUrl,
  });

  /// 判断 URL 是否可直接播放（.mp4 / .m3u8），无需经过解析器
  bool isDirectStreamUrl(String url);

  /// 取消当前进行中的解析
  void cancel();

  /// 释放资源（WebView、torrent client 等）
  void dispose();
}
