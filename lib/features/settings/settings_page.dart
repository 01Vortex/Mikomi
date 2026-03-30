import 'package:flutter/material.dart';
import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:provider/provider.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/hardware_decode_service.dart';
import 'package:mikomi/features/settings/account/account_manage_page.dart';
import 'package:mikomi/core/services/auth_service.dart';
import 'package:mikomi/shared/widgets/message_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final PlaySettingsService _basisService = PlaySettingsService();
  final HardwareDecodeService _hwService = HardwareDecodeService();

  bool _autoPlayNext = true;
  bool _showDanmaku = true;
  double _playSpeed = 1.0;
  bool _hardwareDecoding = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoPlayNext = await _basisService.getAutoPlayNext();
    final playSpeed = await _basisService.getPlaySpeed();
    final hardwareDecoding = await _hwService.getEnabled();

    if (mounted) {
      setState(() {
        _autoPlayNext = autoPlayNext;
        _playSpeed = playSpeed;
        _hardwareDecoding = hardwareDecoding;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isLoggedIn = authService.isLoggedIn;

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
          // 账号设置
          SettingsSection(
            title: const Text('账号'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsPage(),
                    ),
                  );
                },
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('账号管理'),
                description: const Text('查看和管理账号信息'),
              ),
              if (isLoggedIn)
                SettingsTile.navigation(
                  onPressed: (_) => _showLogoutDialog(context, authService),
                  leading: const Icon(Icons.logout),
                  title: const Text('退出登录'),
                )
              else
                SettingsTile.navigation(
                  onPressed: (_) {
                    Navigator.pushNamed(context, '/login');
                  },
                  leading: const Icon(Icons.login),
                  title: const Text('登录'),
                ),
            ],
          ),

          // 视频播放
          SettingsSection(
            title: const Text('视频播放'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {
                  Navigator.pushNamed(context, '/video_basis')
                      .then((_) => _loadSettings());
                },
                leading: const Icon(Icons.play_circle_outlined),
                title: const Text('播放设置'),
                description: Text(_autoPlayNext ? '自动连播已启用' : '自动连播已关闭'),
              ),
              SettingsTile.navigation(
                onPressed: (_) {
                  Navigator.pushNamed(context, '/plugin_manage');
                },
                leading: const Icon(Icons.video_settings_outlined),
                title: const Text('视频源'),
                description: const Text('管理视频数据源'),
              ),
              SettingsTile.navigation(
                onPressed: (_) {
                  Navigator.pushNamed(context, '/hardware_decode')
                      .then((_) => _loadSettings());
                },
                leading: const Icon(Icons.memory_outlined),
                title: const Text('硬件解码'),
                description: Text(_hardwareDecoding ? '已启用' : '已关闭'),
              ),
            ],
          ),

          // 弹幕设置
          SettingsSection(
            title: const Text('弹幕'),
            tiles: [
              SettingsTile.switchTile(
                onToggle: (value) {
                  setState(() {
                    _showDanmaku = value ?? !_showDanmaku;
                  });
                },
                leading: const Icon(Icons.subtitles_outlined),
                title: const Text('显示弹幕'),
                description: const Text('总是开启弹幕'),
                initialValue: _showDanmaku,
              ),
            ],
          ),

          // 关于
          SettingsSection(
            title: const Text('关于'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) => _showAboutDialog(context),
                leading: const Icon(Icons.info_outline),
                title: const Text('关于 Mikomi'),
                description: const Text('版本 1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pop(context);
                MessageDialog.success(context, '已退出登录');
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 Mikomi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mikomi v1.0.0'),
            SizedBox(height: 12),
            Text(
              '一个简洁高效的动漫播放器',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
