import 'package:flutter/foundation.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';
import 'package:mikomi/features/video/repository/danmaku_repository.dart';

class DanmakuService {
  static const int _maxDanmakuPerSecond = 24;

  static final Map<int, int> _bgmToDanDanCache = {};
  static final Map<String, int> _titleToDanDanCache = {};

  final DanmakuRepository _danmakuRepository = DanmakuRepository();
  DanmakuController? canvasController;

  /// 弹幕数据，按秒分组
  Map<int, List<Danmaku>> danmakuMap = {};

  bool isLoaded = false;
  int? danmakuBangumiId;
  String? lastError;

  /// 通过番剧标题加载弹幕
  Future<bool> loadDanmakuByTitle(String title, int episode) async {
    clear();
    try {
      final titleKey = _normalizeTitle(title);
      final bangumiId = _titleToDanDanCache[titleKey] ??
          await _danmakuRepository.getBangumiIdByTitle(title);

      if (bangumiId == 0) {
        lastError = '未找到弹幕番剧ID';
        return false;
      }

      _titleToDanDanCache[titleKey] = bangumiId;
      danmakuBangumiId = bangumiId;

      final danmakus = await _danmakuRepository.getDanmakuByEpisode(bangumiId, episode);
      _groupDanmakuBySecond(danmakus);

      isLoaded = danmakuMap.isNotEmpty;
      if (!isLoaded) lastError = '当前剧集暂无弹幕';
      return isLoaded;
    } catch (e) {
      clear();
      lastError = '加载弹幕失败: $e';
      debugPrint('DanmakuService: $lastError');
      return false;
    }
  }

  /// 通过 Bangumi ID 加载弹幕
  Future<bool> loadDanmakuByBangumiId(
    int bangumiId,
    int episode, {
    String? fallbackTitle,
  }) async {
    clear();
    try {
      final cachedDanDanId = _bgmToDanDanCache[bangumiId];
      int finalDanDanId =
          cachedDanDanId ?? await _danmakuRepository.getDanDanBangumiIdByBgmId(bangumiId);

      if (finalDanDanId == 0 && fallbackTitle != null && fallbackTitle.isNotEmpty) {
        final titleKey = _normalizeTitle(fallbackTitle);
        finalDanDanId = _titleToDanDanCache[titleKey] ??
            await _danmakuRepository.getBangumiIdByTitle(fallbackTitle);
        if (finalDanDanId > 0) _titleToDanDanCache[titleKey] = finalDanDanId;
      }

      if (finalDanDanId == 0) {
        lastError = '未找到弹幕番剧ID';
        return false;
      }

      _bgmToDanDanCache[bangumiId] = finalDanDanId;
      danmakuBangumiId = finalDanDanId;

      final danmakus =
          await _danmakuRepository.getDanmakuByEpisode(finalDanDanId, episode);
      _groupDanmakuBySecond(danmakus);

      isLoaded = danmakuMap.isNotEmpty;
      if (!isLoaded) lastError = '当前剧集暂无弹幕';
      return isLoaded;
    } catch (e) {
      clear();
      lastError = '加载弹幕失败: $e';
      debugPrint('DanmakuService: $lastError');
      return false;
    }
  }

  void _groupDanmakuBySecond(List<Danmaku> danmakus) {
    final deduplicated = <String>{};
    for (final danmaku in danmakus) {
      final second = danmaku.time.floor();
      final normalized = _normalizeDanmakuText(danmaku.message);
      final dedupeKey = '$second|${danmaku.type}|$normalized';
      if (normalized.isEmpty || deduplicated.contains(dedupeKey)) continue;
      deduplicated.add(dedupeKey);
      final list = danmakuMap.putIfAbsent(second, () => []);
      if (list.length < _maxDanmakuPerSecond) list.add(danmaku);
    }
  }

  String _normalizeDanmakuText(String text) =>
      text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  String _normalizeTitle(String title) {
    var normalized = title.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[：:·\-—_]'), ' ');
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 获取指定时间的弹幕
  List<Danmaku> getDanmakuAtTime(int second) => danmakuMap[second] ?? [];

  /// 清空弹幕
  void clear() {
    danmakuMap.clear();
    isLoaded = false;
    danmakuBangumiId = null;
    lastError = null;
  }

  void dispose() => clear();
}
