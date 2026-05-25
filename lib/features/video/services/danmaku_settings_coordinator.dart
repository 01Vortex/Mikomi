import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';

/// 封装弹幕设置的加载与持久化，消除 VideoPageController 对静态方法的直接依赖。
///
/// 所有方法通过实例 [DanmakuSettingService] 调用，保证依赖可注入与可测试。
class DanmakuSettingsCoordinator {
  final DanmakuSettingService _service;

  DanmakuSettingsCoordinator({DanmakuSettingService? service})
    : _service = service ?? DanmakuSettingService();

  /// 是否在播放时默认显示弹幕
  Future<bool> getEnabled() => _service.getShowDanmaku();

  Future<void> setEnabled(bool value) => _service.setShowDanmaku(value);

  /// 从持久化存储加载完整弹幕配置
  Future<DanmakuConfig> loadConfig() => _service.loadConfig();

  /// 一次性持久化完整弹幕配置（8 个字段）
  Future<void> saveConfig(DanmakuConfig config) async {
    await Future.wait([
      _service.saveFontSize(config.fontSize),
      _service.saveOpacity(config.opacity),
      _service.saveArea(config.area),
      _service.saveDuration(config.duration),
      _service.saveStrokeWidth(config.strokeWidth),
      _service.saveShowTop(config.showTop),
      _service.saveShowBottom(config.showBottom),
      _service.saveShowScroll(config.showScroll),
    ]);
  }
}
