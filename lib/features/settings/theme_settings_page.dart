import 'package:flutter/material.dart';
import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:mikomi/core/providers/theme_provider.dart';
import 'package:mikomi/features/my/ui/widgets/color_palette_card.dart';
import 'package:provider/provider.dart';

class ThemePage extends StatefulWidget {
  const ThemePage({super.key});

  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  final MenuController _fontMenuController = MenuController();

  final List<Map<String, dynamic>> _colorThemes = [
    {'name': '默认蓝', 'color': Colors.blue},
    {'name': '活力橙', 'color': Colors.orange},
    {'name': '清新绿', 'color': Colors.green},
    {'name': '优雅紫', 'color': Colors.purple},
    {'name': '浪漫粉', 'color': Colors.pink},
    {'name': '深邃靛', 'color': Colors.indigo},
    {'name': '热情红', 'color': Colors.red},
    {'name': '青柠绿', 'color': Colors.lime},
    {'name': '天空蓝', 'color': Colors.cyan},
    {'name': '琥珀黄', 'color': Colors.amber},
  ];

  final Map<String, String> _fontMap = {'system': '系统默认', 'lxgw': '霞鹜文楷'};

  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择配色方案'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorThemes.map((theme) {
              final isSelected =
                  !themeProvider.useDynamicColor &&
                  themeProvider.themeColor?.value == theme['color'].value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPaletteCard(
                    color: theme['color'],
                    selected: isSelected,
                    onTap: () {
                      themeProvider.setThemeColor(theme['color']);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(theme['name'], style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _updateFont(String font) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.setFontFamily(font);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('主题设置'), centerTitle: true),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('主题'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) => _showColorPicker(context, themeProvider),
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('配色方案'),
                description: const Text('选择应用主题颜色'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeProvider.useDynamicColor
                        ? Theme.of(context).colorScheme.primary
                        : (themeProvider.themeColor ?? Colors.blue),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                ),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {
                  themeProvider.setUseDynamicColor(value ?? false);
                },
                leading: const Icon(Icons.palette_outlined),
                title: const Text('动态配色'),
                description: const Text('使用系统壁纸颜色'),
                initialValue: themeProvider.useDynamicColor,
              ),
            ],
          ),
          SettingsSection(
            title: const Text('字体'),
            tiles: [
              SettingsTile.navigation(
                onPressed: (_) {
                  if (_fontMenuController.isOpen) {
                    _fontMenuController.close();
                  } else {
                    _fontMenuController.open();
                  }
                },
                leading: const Icon(Icons.font_download_outlined),
                title: const Text('字体'),
                value: MenuAnchor(
                  consumeOutsideTap: true,
                  controller: _fontMenuController,
                  builder: (context, controller, child) {
                    return Text(_fontMap[themeProvider.fontFamily] ?? '系统默认');
                  },
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => _updateFont('system'),
                      child: SizedBox(
                        height: 48,
                        width: 120,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '系统默认',
                            style: TextStyle(
                              color: themeProvider.fontFamily == 'system'
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    MenuItemButton(
                      onPressed: () => _updateFont('lxgw'),
                      child: SizedBox(
                        height: 48,
                        width: 120,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '霞鹜文楷',
                            style: TextStyle(
                              fontFamily: 'LXGWWenKai',
                              color: themeProvider.fontFamily == 'lxgw'
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
