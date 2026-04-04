import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';
import 'package:mikomi/features/video/services/danmaku_service.dart';

class DanmakuController extends ChangeNotifier {
  final DanmakuService _service;

  DanmakuController({DanmakuService? service})
    : _service = service ?? DanmakuService();

  Map<int, List<Danmaku>> get danmakuMap => _service.danmakuMap;
  bool get isLoaded => _service.isLoaded;
  int? get danmakuBangumiId => _service.danmakuBangumiId;
  String? get lastError => _service.lastError;

  Future<bool> loadByTitle(String title, int episode) async {
    final result = await _service.loadDanmakuByTitle(title, episode);
    notifyListeners();
    return result;
  }

  Future<bool> loadByBangumiId(
    int bangumiId,
    int episode, {
    String? fallbackTitle,
  }) async {
    final result = await _service.loadDanmakuByBangumiId(
      bangumiId,
      episode,
      fallbackTitle: fallbackTitle,
    );
    notifyListeners();
    return result;
  }

  List<Danmaku> getDanmakuAtTime(int second) {
    return _service.getDanmakuAtTime(second);
  }

  void clear() {
    _service.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
