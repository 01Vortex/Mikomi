import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';

class DanmakuBroadcaster {
  final List<dynamic> _controllers = [];

  bool get isEmpty => _controllers.isEmpty;

  void register(dynamic controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  void unregister(dynamic controller) {
    _controllers.remove(controller);
  }

  void send(List<Danmaku> danmakus) {
    if (_controllers.isEmpty || danmakus.isEmpty) return;
    for (final danmaku in danmakus) {
      final item = DanmakuContentItem(
        danmaku.message,
        color: danmaku.color,
        type: danmaku.type == 5
            ? DanmakuItemType.top
            : danmaku.type == 4
                ? DanmakuItemType.bottom
                : DanmakuItemType.scroll,
      );
      for (final controller in _controllers) {
        (controller as DanmakuController).addDanmaku(item);
      }
    }
  }

  void clear() => _controllers.clear();
}
