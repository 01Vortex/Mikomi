import 'package:flutter/material.dart';
import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:mikomi/features/settings/video_settings/service/play_settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PlayService _playService = PlayService();

  bool _autoPlayNext = true;
  bool _privateMode = false;
  bool _wifiOnlyDownload = true;
  bool _hardwareDecoding = true;
  bool _showDanmaku = true;
  double _playSpeed = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hardwareDecoding = await _playService.getHardwareDecoding();
    final autoPlayNext = await _playService.getAutoPlayNext();
    final playSpeed = await _playService.getPlaySpeed();

    if (mounted) {
      setState(() {
        _hardwareDecoding = hardwareDecoding;
        _autoPlayNext = autoPlayNext;
        _playSpeed = playSpeed;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('播放设置'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {
                  Navigator.pushNamed(context, '/plugin_manage');
                },
                leading: const Icon(Icons.video_settings_outlined),
                title: const Text('视频源管理'),
                description: const Text('管理视频数据源'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) async {
                  final newValue = value ?? !_hardwareDecoding;
                  await _playService.setHardwareDecoding(newValue);
                  setState(() {
                    _hardwareDecoding = newValue;
                  });
                },
                leading: const Icon(Icons.hardware_outlined),
                title: const Text('硬件解码'),
                description: const Text('启用硬件加速解码'),
                initialValue: _hardwareDecoding,
              ),
              SettingsTile.switchTile(
                onToggle: (value) async {
                  final newValue = value ?? !_autoPlayNext;
                  await _playService.setAutoPlayNext(newValue);
                  setState(() {
                    _autoPlayNext = newValue;
                  });
                },
                leading: const Icon(Icons.skip_next_outlined),
                title: const Text('自动连播'),
                description: const Text('当前视频播放完毕后自动播放下一集'),
                initialValue: _autoPlayNext,
              ),
              SettingsTile(
                leading: const Icon(Icons.speed_outlined),
                title: const Text('默认倍速'),
                description: Slider(
                  value: _playSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  label: '${_playSpeed}x',
                  onChanged: (value) {
                    setState(() {
                      _playSpeed = value;
                    });
                  },
                  onChangeEnd: (value) async {
                    await _playService.setPlaySpeed(value);
                  },
                ),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('弹幕设置'),
            tiles: [
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    _showDanmaku = value ?? !_showDanmaku;
                  });
                },
                leading: const Icon(Icons.subtitles_outlined),
                title: const Text('显示弹幕'),
                description: const Text('播放时显示弹幕'),
                initialValue: _showDanmaku,
              ),
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.text_fields_outlined),
                title: const Text('弹幕样式'),
                description: const Text('设置弹幕字体、大小和透明度'),
              ),
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.filter_list_outlined),
                title: const Text('弹幕过滤'),
                description: const Text('设置弹幕屏蔽规则'),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('下载设置'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.folder_outlined),
                title: const Text('下载路径'),
                description: const Text('设置视频下载位置'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    _wifiOnlyDownload = value ?? !_wifiOnlyDownload;
                  });
                },
                leading: const Icon(Icons.wifi_outlined),
                title: const Text('仅WiFi下载'),
                description: const Text('节省移动数据'),
                initialValue: _wifiOnlyDownload,
              ),
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.storage_outlined),
                title: const Text('缓存管理'),
                description: const Text('清理应用缓存'),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('主题设置'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('深色模式'),
                description: const Text('跟随系统'),
              ),
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('主题色'),
                description: const Text('选择应用主题颜色'),
              ),
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.language_outlined),
                title: const Text('语言'),
                description: const Text('简体中文'),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('隐私与安全'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.history_outlined),
                title: const Text('播放记录'),
                description: const Text('管理观看历史'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    _privateMode = value ?? !_privateMode;
                  });
                },
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('隐身模式'),
                description: const Text('不保留观看记录'),
                initialValue: _privateMode,
              ),
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.delete_outline),
                title: const Text('清除数据'),
                description: const Text('清除所有本地数据'),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('其他'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {},
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                description: const Text('版本 1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
