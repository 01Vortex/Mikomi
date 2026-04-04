import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';

class DanmakuBroadcaster {
  final List<DanmakuController> _controllers = [];

  void register(DanmakuController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  void unregister(DanmakuController controller) {
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
      for (final ctrl in _controllers) {
        ctrl.addDanmaku(item);
      }
    }
  }

  void clear() => _controllers.clear();
}
