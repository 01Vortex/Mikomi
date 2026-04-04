import 'package:flutter/material.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';
import 'package:mikomi/features/video/repository/danmaku_repository.dart';

class DanmakuService {
  static const int maxDanmakuPerSecond = 24;

  final DanmakuRepository _danmakuRepository;

  Map<int, List<Danmaku>> _danmakuBySecond = {};
  bool _isLoaded = false;
  int? _loadedBangumiId;
  String? _lastError;

  DanmakuService({DanmakuRepository? danmakuRepository})
    : _danmakuRepository = danmakuRepository ?? DanmakuRepository();

  Map<int, List<Danmaku>> get danmakuMap => _danmakuBySecond;
  bool get isLoaded => _isLoaded;
  int? get danmakuBangumiId => _loadedBangumiId;
  String? get lastError => _lastError;

  Future<bool> loadDanmakuByTitle(String title, int episode) async {
    clear();
    try {
      final resolvedBangumiId = await _danmakuRepository.resolveBangumiIdByTitle(
        title,
      );
      if (resolvedBangumiId == null) {
        _lastError = '未找到对应弹幕番剧';
        return false;
      }

      return await loadDanmakuByBangumiId(resolvedBangumiId, episode);
    } catch (e) {
      clear();
      _lastError = '加载弹幕失败: $e';
      debugPrint('DanmakuService: $_lastError');
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
      final resolvedEpisodeId = await _danmakuRepository.resolveEpisodeIdByBangumiId(
        bangumiId,
        episode,
      );

      if (resolvedEpisodeId == null && fallbackTitle != null) {
        final fallbackBangumiId = await _danmakuRepository.resolveBangumiIdByTitle(
          fallbackTitle,
        );
        if (fallbackBangumiId != null) {
          return loadDanmakuByBangumiId(fallbackBangumiId, episode);
        }
      }

      if (resolvedEpisodeId == null) {
        _lastError = '未找到当前剧集的弹幕';
        return false;
      }

      final rawComments = await _danmakuRepository.fetchCommentsByEpisodeId(
        resolvedEpisodeId,
      );
      final parsedDanmakus = _parseDanmakus(rawComments);
      _groupDanmakuBySecond(parsedDanmakus);

      _loadedBangumiId = bangumiId;
      _isLoaded = _danmakuBySecond.isNotEmpty;
      if (!_isLoaded) {
        _lastError = '当前剧集暂无弹幕';
      }
      return _isLoaded;
    } catch (e) {
      clear();
      _lastError = '加载弹幕失败: $e';
      debugPrint('DanmakuService: $_lastError');
      return false;
    }
  }

  List<Danmaku> getDanmakuAtTime(int second) {
    return _danmakuBySecond[second] ?? const [];
  }

  void clear() {
    _danmakuBySecond = {};
    _isLoaded = false;
    _loadedBangumiId = null;
    _lastError = null;
  }

  void dispose() {}

  List<Danmaku> _parseDanmakus(List<dynamic> rawComments) {
    return rawComments
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['p'] != null && item['m'] != null)
        .map(Danmaku.fromJson)
        .toList();
  }

  void _groupDanmakuBySecond(List<Danmaku> danmakus) {
    _danmakuBySecond = {};
    for (final danmaku in danmakus) {
      final second = danmaku.time.floor();
      final bucket = _danmakuBySecond.putIfAbsent(second, () => []);
      if (bucket.length < maxDanmakuPerSecond) {
        bucket.add(danmaku);
      }
    }
  }
}
