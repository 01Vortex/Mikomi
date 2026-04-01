import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/models/danmaku.dart';

/// 弹幕广播管理器
/// 小屏和全屏的 [DanmakuController] 都注册到这里
/// 发弹幕时自动广播给所有已注册的 controller
class DanmakuBroadcaster {
  final List<DanmakuController> _controllers = [];

  /// 注册一个 canvas controller
  void register(DanmakuController controller) {
    if (!_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  /// 注销一个 canvas controller
  void unregister(DanmakuController controller) {
    _controllers.remove(controller);
  }

  /// 向所有已注册 controller 发送弹幕列表
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

  /// 清空所有注册
  void clear() => _controllers.clear();
}
