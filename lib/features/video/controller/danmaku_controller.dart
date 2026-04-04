import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/controller/danmaku_broadcaster.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';
import 'package:mikomi/features/video/services/danmaku_service.dart';

class DanmakuController extends ChangeNotifier {
  final DanmakuService _danmakuService;
  final DanmakuBroadcaster _danmakuBroadcaster = DanmakuBroadcaster();

  int _lastSyncedSecond = -1;
  int _lastLoadedEpisode = -1;
  bool _isLoadingDanmaku = false;

  DanmakuController({DanmakuService? danmakuService})
    : _danmakuService = danmakuService ?? DanmakuService();

  Map<int, List<Danmaku>> get danmakuMap => _danmakuService.danmakuMap;
  bool get isLoaded => _danmakuService.isLoaded;
  bool get isLoadingDanmaku => _isLoadingDanmaku;
  int? get danmakuBangumiId => _danmakuService.danmakuBangumiId;
  String? get lastError => _danmakuService.lastError;
  DanmakuBroadcaster get danmakuBroadcaster => _danmakuBroadcaster;

  Future<bool> loadDanmaku({
    required bool isDanmakuEnabled,
    required int episode,
    required int displayedEpisode,
    int? bangumiId,
    String? animeTitle,
  }) async {
    debugPrint('========== 开始加载弹幕 ==========');
    debugPrint('弹幕开关状态: $isDanmakuEnabled');
    debugPrint('番剧ID: $bangumiId');
    debugPrint('番剧标题: $animeTitle');
    debugPrint('当前集数: $displayedEpisode');

    if (!isDanmakuEnabled) {
      debugPrint('弹幕未开启,跳过加载');
      debugPrint('==================================');
      return false;
    }

    if (_isLoadingDanmaku) {
      return false;
    }

    if (_lastLoadedEpisode == displayedEpisode && isLoaded) {
      return true;
    }

    _isLoadingDanmaku = true;
    notifyListeners();

    bool didLoadDanmaku = false;
    try {
      if (bangumiId != null) {
        didLoadDanmaku = await _danmakuService.loadDanmakuByBangumiId(
          bangumiId,
          episode,
          fallbackTitle: animeTitle,
        );
      } else if (animeTitle != null) {
        didLoadDanmaku = await _danmakuService.loadDanmakuByTitle(
          animeTitle,
          episode,
        );
      } else {
        debugPrint('没有番剧ID或标题,无法加载弹幕');
      }

      _lastLoadedEpisode = displayedEpisode;
      _lastSyncedSecond = -1;

      debugPrint('弹幕加载完成,已加载: $isLoaded');
      debugPrint('弹幕数据量: ${danmakuMap.length} 秒');
      debugPrint('==================================');
      return didLoadDanmaku;
    } finally {
      _isLoadingDanmaku = false;
      notifyListeners();
    }
  }

  void attachCanvasController(dynamic canvasController) {
    _danmakuBroadcaster.register(canvasController);
  }

  void detachCanvasController(dynamic canvasController) {
    _danmakuBroadcaster.unregister(canvasController);
  }

  void syncPlaybackPosition({
    required bool isDanmakuEnabled,
    required bool isPlaying,
    required Duration position,
  }) {
    if (!isDanmakuEnabled || !isPlaying || !isLoaded) {
      return;
    }

    final currentSecond = position.inSeconds;
    if ((currentSecond - _lastSyncedSecond).abs() > 2) {
      _lastSyncedSecond = currentSecond;
      _sendDanmakuWindow(currentSecond);
    } else if (currentSecond != _lastSyncedSecond) {
      _lastSyncedSecond = currentSecond;
      _sendDanmakuAtSecond(currentSecond);
    }
  }

  List<Danmaku> getDanmakuAtTime(int second) {
    return _danmakuService.getDanmakuAtTime(second);
  }

  void clear() {
    _lastSyncedSecond = -1;
    _lastLoadedEpisode = -1;
    _danmakuService.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _danmakuBroadcaster.clear();
    _danmakuService.dispose();
    super.dispose();
  }

  void _sendDanmakuAtSecond(int second) {
    final danmakus = _danmakuService.getDanmakuAtTime(second);
    _danmakuBroadcaster.send(danmakus);
  }

  void _sendDanmakuWindow(int centerSecond) {
    _sendDanmakuAtSecond(centerSecond - 1);
    _sendDanmakuAtSecond(centerSecond);
    _sendDanmakuAtSecond(centerSecond + 1);
  }
}
