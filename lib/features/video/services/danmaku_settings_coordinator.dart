import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';

/// 封装弹幕设置的加载与持久化，消除 VideoPageController 对静态方法的直接依赖。
///
/// 与 [DanmakuSettingService] 的关系：
/// - 实例方法代理静态调用，方便依赖注入和测试替换
/// - [loadConfig] 一次性返回完整 [DanmakuConfig]
/// - [saveConfig] 一次性持久化完整配置
class DanmakuSettingsCoordinator {
  final DanmakuSettingService _service;

  DanmakuSettingsCoordinator({DanmakuSettingService? service})
    : _service = service ?? DanmakuSettingService();

  /// 是否在播放时默认显示弹幕
  Future<bool> getEnabled() => _service.getShowDanmaku();

  Future<void> setEnabled(bool value) => _service.setShowDanmaku(value);

  /// 从持久化存储加载完整弹幕配置
  Future<DanmakuConfig> loadConfig() => DanmakuSettingService.loadAll();

  /// 一次性持久化完整弹幕配置（8 个字段）
  Future<void> saveConfig(DanmakuConfig config) async {
    await Future.wait([
      DanmakuSettingService.setFontSize(config.fontSize),
      DanmakuSettingService.setOpacity(config.opacity),
      DanmakuSettingService.setArea(config.area),
      DanmakuSettingService.setDuration(config.duration),
      DanmakuSettingService.setStrokeWidth(config.strokeWidth),
      DanmakuSettingService.setShowTop(config.showTop),
      DanmakuSettingService.setShowBottom(config.showBottom),
      DanmakuSettingService.setShowScroll(config.showScroll),
    ]);
  }
}
