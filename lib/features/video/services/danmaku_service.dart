import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';

class DanmakuService {
  static const int _maxDanmakuPerSecond = 24;

  DanmakuController? canvasController;
  Map<int, List<Danmaku>> danmakuMap = {};

  bool isLoaded = false;
  int? danmakuBangumiId;
  String? lastError;

  Future<bool> loadDanmakuByTitle(String title, int episode) async {
    clear();
    try {
      danmakuBangumiId = title.hashCode.abs();
      _groupDanmakuBySecond(_mockDanmaku(episode));
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

  Future<bool> loadDanmakuByBangumiId(
    int bangumiId,
    int episode, {
    String? fallbackTitle,
  }) async {
    clear();
    try {
      danmakuBangumiId = bangumiId;
      _groupDanmakuBySecond(_mockDanmaku(episode));
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

  void attachController(DanmakuController controller) {
    canvasController = controller;
  }

  List<Danmaku> getDanmakuAtTime(int second) {
    return danmakuMap[second] ?? const [];
  }

  void clear() {
    danmakuMap.clear();
    isLoaded = false;
    danmakuBangumiId = null;
    lastError = null;
    canvasController?.clear();
  }

  void dispose() {
    canvasController = null;
  }

  void _groupDanmakuBySecond(List<Danmaku> danmakus) {
    danmakuMap.clear();
    for (final danmaku in danmakus) {
      final second = danmaku.time.floor();
      final bucket = danmakuMap.putIfAbsent(second, () => []);
      if (bucket.length < _maxDanmakuPerSecond) {
        bucket.add(danmaku);
      }
    }
  }

  List<Danmaku> _mockDanmaku(int episode) {
    return List.generate(12, (index) {
      return Danmaku(
        message: '弹幕 ${index + 1}',
        time: index + 1.0,
        type: 1,
        color: const Color(0xFFFFFFFF),
        source: 'mock-$episode',
      );
    });
  }
}
