import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/core/models/danmaku.dart';
import 'package:mikomi/core/services/danmaku_service.dart';

class DanmakuManagerService {
  final DanmakuService _danmakuService = DanmakuService();
  DanmakuController? canvasController;

  // 弹幕数据，按秒分组
  Map<int, List<Danmaku>> danmakuMap = {};

  // 是否已加载弹幕
  bool isLoaded = false;

  // 弹幕番剧ID
  int? danmakuBangumiId;

  /// 通过番剧标题加载弹幕
  Future<void> loadDanmakuByTitle(String title, int episode) async {
    try {
      debugPrint('========== 加载弹幕 ==========');
      debugPrint('番剧标题: $title');
      debugPrint('集数: $episode');

      // 搜索番剧ID
      final bangumiId = await _danmakuService.getBangumiIdByTitle(title);
      if (bangumiId == 0) {
        debugPrint('未找到弹幕番剧ID');
        return;
      }

      danmakuBangumiId = bangumiId;
      debugPrint('弹幕番剧ID: $bangumiId');

      // 获取弹幕
      final danmakus = await _danmakuService.getDanmakuByEpisode(
        bangumiId,
        episode,
      );

      debugPrint('加载弹幕数量: ${danmakus.length}');

      // 按秒分组
      danmakuMap.clear();
      for (var danmaku in danmakus) {
        final second = danmaku.time.floor();
        if (!danmakuMap.containsKey(second)) {
          danmakuMap[second] = [];
        }
        danmakuMap[second]!.add(danmaku);
      }

      isLoaded = true;
      debugPrint('弹幕加载完成');
      debugPrint('==================================');
    } catch (e) {
      debugPrint('加载弹幕失败: $e');
    }
  }

  /// 通过Bangumi ID加载弹幕
  Future<void> loadDanmakuByBangumiId(
    int bangumiId,
    int episode, {
    String? fallbackTitle,
  }) async {
    try {
      debugPrint('========== 加载弹幕 ==========');
      debugPrint('Bangumi ID: $bangumiId');
      debugPrint('集数: $episode');

      // 获取弹弹Play番剧ID
      final danDanId = await _danmakuService.getDanDanBangumiIdByBgmId(
        bangumiId,
      );

      int finalDanDanId = danDanId;

      // 如果通过Bangumi ID获取失败，尝试使用标题搜索
      if (danDanId == 0 && fallbackTitle != null) {
        debugPrint('通过Bangumi ID获取失败，尝试使用标题搜索: $fallbackTitle');
        finalDanDanId = await _danmakuService.getBangumiIdByTitle(
          fallbackTitle,
        );
      }

      if (finalDanDanId == 0) {
        debugPrint('未找到弹幕番剧ID');
        return;
      }

      danmakuBangumiId = finalDanDanId;
      debugPrint('弹幕番剧ID: $finalDanDanId');

      // 获取弹幕
      final danmakus = await _danmakuService.getDanmakuByEpisode(
        finalDanDanId,
        episode,
      );

      debugPrint('加载弹幕数量: ${danmakus.length}');

      // 按秒分组
      danmakuMap.clear();
      for (var danmaku in danmakus) {
        final second = danmaku.time.floor();
        if (!danmakuMap.containsKey(second)) {
          danmakuMap[second] = [];
        }
        danmakuMap[second]!.add(danmaku);
      }

      isLoaded = true;
      debugPrint('弹幕加载完成');
      debugPrint('==================================');
    } catch (e) {
      debugPrint('加载弹幕失败: $e');
    }
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
  }

  /// 释放资源
  void dispose() {
    clear();
  }
}
