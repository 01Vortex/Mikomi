import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mikomi/core/models/app_theme_model.dart';
import 'package:mikomi/core/providers/app_theme_provider.dart';
import 'package:mikomi/core/providers/theme_font_provider.dart';
import 'package:mikomi/core/providers/theme_animation_provider.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  final MenuController _fontMenuController = MenuController();
  final MenuController _animationMenuController = MenuController();

  final Map<String, String> _fontMap = {'system': '系统默认', 'lxgw': '霞鹜文楷'};

  void _showThemePicker(BuildContext context, AppThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('配色方案'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: AppTheme.allThemes.map((theme) {
              final isSelected = themeProvider.currentTheme.id == theme.id;
              return _ThemeCircle(
                theme: theme,
                isSelected: isSelected,
                onTap: () {
                  themeProvider.setTheme(theme);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
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

  void _updateFont(String font) {
    final fontProvider = Provider.of<FontProvider>(context, listen: false);
    fontProvider.setFontFamily(font);
  }

  void _updateAnimationStyle(HeroAnimationStyle style) {
    final animationProvider = Provider.of<AnimationProvider>(
      context,
      listen: false,
    );
    animationProvider.setHeroAnimationStyle(style);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<AppThemeProvider>(context);
    final fontProvider = Provider.of<FontProvider>(context);
    final animationProvider = Provider.of<AnimationProvider>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              '主题',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          _SectionCard(
            children: [
              ListTile(
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: themeProvider.currentTheme.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.outline, width: 1),
                  ),
                ),
                title: const Text('选择主题'),
                subtitle: Text(themeProvider.currentTheme.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemePicker(context, themeProvider),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              '高级选项',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          _SectionCard(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.palette_outlined),
                title: const Text('动态配色'),
                subtitle: const Text('使用系统壁纸颜色'),
                value: themeProvider.useDynamicColor,
                onChanged: (value) {
                  themeProvider.setUseDynamicColor(value);
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              '字体',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          _SectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.font_download_outlined),
                title: const Text('字体'),
                subtitle: Text(_fontMap[fontProvider.fontFamily] ?? '系统默认'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (_fontMenuController.isOpen) {
                    _fontMenuController.close();
                  } else {
                    _fontMenuController.open();
                  }
                },
              ),
              MenuAnchor(
                consumeOutsideTap: true,
                controller: _fontMenuController,
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      _updateFont('system');
                      _fontMenuController.close();
                    },
                    child: SizedBox(
                      height: 48,
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '系统默认',
                          style: TextStyle(
                            color: fontProvider.fontFamily == 'system'
                                ? cs.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      _updateFont('lxgw');
                      _fontMenuController.close();
                    },
                    child: SizedBox(
                      height: 48,
                      width: 120,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '霞鹜文楷',
                          style: TextStyle(
                            fontFamily: 'LXGWWenKai',
                            color: fontProvider.fontFamily == 'lxgw'
                                ? cs.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              '动画',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          _SectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.animation_outlined),
                title: const Text('页面过渡动画'),
                subtitle: Text(
                  AnimationProvider.getAnimationStyleName(
                    animationProvider.heroAnimationStyle,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (_animationMenuController.isOpen) {
                    _animationMenuController.close();
                  } else {
                    _animationMenuController.open();
                  }
                },
              ),
              MenuAnchor(
                consumeOutsideTap: true,
                controller: _animationMenuController,
                menuChildren: HeroAnimationStyle.values.map((style) {
                  return MenuItemButton(
                    onPressed: () {
                      _updateAnimationStyle(style);
                      _animationMenuController.close();
                    },
                    child: SizedBox(
                      height: 48,
                      width: 150,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AnimationProvider.getAnimationStyleName(style),
                          style: TextStyle(
                            color: animationProvider.heroAnimationStyle == style
                                ? cs.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _ThemeCircle extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCircle({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryLightest,
                    theme.colorScheme.primaryLighter,
                    theme.colorScheme.primaryLight,
                    theme.primaryColor,
                  ],
                  stops: const [0.0, 0.33, 0.66, 1.0],
                ),
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 3 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 28,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            theme.name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? theme.primaryColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
