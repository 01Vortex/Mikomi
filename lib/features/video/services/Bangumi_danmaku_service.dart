import 'package:flutter/foundation.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/core/models/danmaku.dart';
import 'package:mikomi/core/services/danmaku_service.dart';

class BangumiDanmakuService {
  static const int _maxDanmakuPerSecond = 24;

  static final Map<int, int> _bgmToDanDanCache = {};
  static final Map<String, int> _titleToDanDanCache = {};

  final DanmakuService _danmakuService = DanmakuService();
  DanmakuController? canvasController;

  // 弹幕数据，按秒分组
  Map<int, List<Danmaku>> danmakuMap = {};

  // 是否已加载弹幕
  bool isLoaded = false;

  // 弹幕番剧ID
  int? danmakuBangumiId;

  // 最近一次错误（用于 UI 提示）
  String? lastError;

  /// 通过番剧标题加载弹幕
  Future<bool> loadDanmakuByTitle(String title, int episode) async {
    clear();

    try {
      debugPrint('========== 加载弹幕 ==========');
      debugPrint('番剧标题: $title');
      debugPrint('集数: $episode');

      final titleKey = _normalizeTitle(title);
      final cached = _titleToDanDanCache[titleKey];
      final bangumiId =
          cached ?? await _danmakuService.getBangumiIdByTitle(title);

      if (bangumiId == 0) {
        lastError = '未找到弹幕番剧ID';
        debugPrint(lastError!);
        return false;
      }

      _titleToDanDanCache[titleKey] = bangumiId;
      danmakuBangumiId = bangumiId;
      debugPrint('弹幕番剧ID: $bangumiId');

      final danmakus = await _danmakuService.getDanmakuByEpisode(
        bangumiId,
        episode,
      );

      debugPrint('加载弹幕数量: ${danmakus.length}');
      _groupDanmakuBySecond(danmakus);

      isLoaded = danmakuMap.isNotEmpty;
      if (!isLoaded) {
        lastError = '当前剧集暂无弹幕';
      }

      debugPrint('弹幕加载完成');
      debugPrint('==================================');
      return isLoaded;
    } catch (e) {
      clear();
      lastError = '加载弹幕失败: $e';
      debugPrint(lastError!);
      return false;
    }
  }

  /// 通过Bangumi ID加载弹幕
  Future<bool> loadDanmakuByBangumiId(
    int bangumiId,
    int episode, {
    String? fallbackTitle,
  }) async {
    clear();

    try {
      debugPrint('========== 加载弹幕 ==========');
      debugPrint('Bangumi ID: $bangumiId');
      debugPrint('集数: $episode');

      final cachedDanDanId = _bgmToDanDanCache[bangumiId];
      final danDanId = cachedDanDanId ??
          await _danmakuService.getDanDanBangumiIdByBgmId(bangumiId);

      int finalDanDanId = danDanId;

      if (danDanId == 0 && fallbackTitle != null && fallbackTitle.isNotEmpty) {
        debugPrint('通过Bangumi ID获取失败，尝试使用标题搜索: $fallbackTitle');
        final titleKey = _normalizeTitle(fallbackTitle);
        final titleCached = _titleToDanDanCache[titleKey];
        finalDanDanId =
            titleCached ?? await _danmakuService.getBangumiIdByTitle(fallbackTitle);

        if (finalDanDanId > 0) {
          _titleToDanDanCache[titleKey] = finalDanDanId;
        }
      }

      if (finalDanDanId == 0) {
        lastError = '未找到弹幕番剧ID';
        debugPrint(lastError!);
        return false;
      }

      _bgmToDanDanCache[bangumiId] = finalDanDanId;
      danmakuBangumiId = finalDanDanId;
      debugPrint('弹幕番剧ID: $finalDanDanId');

      final danmakus = await _danmakuService.getDanmakuByEpisode(
        finalDanDanId,
        episode,
      );

      debugPrint('加载弹幕数量: ${danmakus.length}');
      _groupDanmakuBySecond(danmakus);

      isLoaded = danmakuMap.isNotEmpty;
      if (!isLoaded) {
        lastError = '当前剧集暂无弹幕';
      }

      debugPrint('弹幕加载完成');
      debugPrint('==================================');
      return isLoaded;
    } catch (e) {
      clear();
      lastError = '加载弹幕失败: $e';
      debugPrint(lastError!);
      return false;
    }
  }

  void _groupDanmakuBySecond(List<Danmaku> danmakus) {
    final deduplicated = <String>{};

    for (var danmaku in danmakus) {
      final second = danmaku.time.floor();
      final normalized = _normalizeDanmakuText(danmaku.message);
      final dedupeKey = '$second|${danmaku.type}|$normalized';

      if (normalized.isEmpty || deduplicated.contains(dedupeKey)) {
        continue;
      }
      deduplicated.add(dedupeKey);

      final list = danmakuMap.putIfAbsent(second, () => []);
      if (list.length >= _maxDanmakuPerSecond) {
        continue;
      }
      list.add(danmaku);
    }
  }

  String _normalizeDanmakuText(String text) {
    return text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  String _normalizeTitle(String title) {
    var normalized = title.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[：:·\-—_]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  /// 获取指定时间的弹幕
  List<Danmaku> getDanmakuAtTime(int second) {
    return danmakuMap[second] ?? [];
  }

  /// 清空弹幕
  void clear() {
    danmakuMap.clear();
    isLoaded = false;
    danmakuBangumiId = null;
    lastError = null;
  }

  /// 释放资源
  void dispose() {
    clear();
  }
}
