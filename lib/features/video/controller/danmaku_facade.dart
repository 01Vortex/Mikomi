import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/models/danmaku_model.dart';

/// 弹幕外观控制器——管理多个 [DanmakuController] 实例，统一发送弹幕、应用配置。
class DanmakuFacade {
  final List<DanmakuController> _controllers = [];

  bool get isEmpty => _controllers.isEmpty;

  void register(dynamic controller) {
    if (controller is DanmakuController && !_controllers.contains(controller)) {
      _controllers.add(controller);
    }
  }

  void unregister(dynamic controller) {
    _controllers.remove(controller);
  }

  void applyConfig(DanmakuConfig config) {
    final option = DanmakuOption(
      fontSize: config.fontSize,
      opacity: config.opacity,
      duration: config.duration,
      strokeWidth: config.strokeWidth,
      area: config.area,
      hideTop: !config.showTop,
      hideBottom: !config.showBottom,
      hideScroll: !config.showScroll,
    );
    for (final controller in List<DanmakuController>.of(_controllers)) {
      controller.updateOption(option);
    }
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
      for (final controller in List<DanmakuController>.of(_controllers)) {
        controller.addDanmaku(item);
      }
    }
  }

  void clearScreen() {
    for (final controller in List<DanmakuController>.of(_controllers)) {
      controller.clear();
    }
  }

  void clear() {
    clearScreen();
    _controllers.clear();
  }
}
