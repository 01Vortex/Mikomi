import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';

class DanmakuSettingPage extends StatefulWidget {
  const DanmakuSettingPage({super.key});

  @override
  State<DanmakuSettingPage> createState() => _DanmakuSettingPageState();
}

class _DanmakuSettingPageState extends State<DanmakuSettingPage> {
  final DanmakuSettingService _service = DanmakuSettingService();
  bool _loading = true;

  bool _showDanmaku = false;
  double _fontSize = 16.0;
  double _opacity = 1.0;
  double _area = 0.5;
  double _duration = 8.0;
  double _strokeWidth = 1.0;
  bool _showTop = true;
  bool _showBottom = false;
  bool _showScroll = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final showDanmaku = await _service.getShowDanmaku();
    final config = await DanmakuSettingService.loadAll();
    if (!mounted) return;
    setState(() {
      _showDanmaku = showDanmaku;
      _fontSize = config.fontSize;
      _opacity = config.opacity;
      _area = config.area;
      _duration = config.duration;
      _strokeWidth = config.strokeWidth;
      _showTop = config.showTop;
      _showBottom = config.showBottom;
      _showScroll = config.showScroll;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('弹幕设置'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionCard(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.subtitles_outlined,
                        color: _showDanmaku ? cs.primary : cs.onSurfaceVariant,
                      ),
                      title: const Text('显示弹幕'),
                      subtitle: const Text('播放时默认开启弹幕'),
                      value: _showDanmaku,
                      onChanged: (v) {
                        setState(() => _showDanmaku = v);
                        _service.setShowDanmaku(v);
                      },
                    ),
                  ],
                ),
                if (_showDanmaku) ...[
                  _sectionLabel('样式', context),
                  _SectionCard(
                    children: [
                      _sliderTile(
                        context,
                        icon: Icons.text_fields_rounded,
                        label: '字体大小',
                        value: _fontSize,
                        min: 10,
                        max: 32,
                        display: '${_fontSize.floor()}',
                        onChanged: (v) => setState(() => _fontSize = v.floorToDouble()),
                        onSave: (v) => DanmakuSettingService.setFontSize(v.floorToDouble()),
                      ),
                      _divider(context),
                      _sliderTile(
                        context,
                        icon: Icons.opacity_rounded,
                        label: '不透明度',
                        value: _opacity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 18,
                        display: '${(_opacity * 100).round()}%',
                        onChanged: (v) => setState(() => _opacity = v),
                        onSave: DanmakuSettingService.setOpacity,
                      ),
                      _divider(context),
                      _sliderTile(
                        context,
                        icon: Icons.border_color_rounded,
                        label: '描边粗细',
                        value: _strokeWidth,
                        min: 0.0,
                        max: 3.0,
                        divisions: 30,
                        display: _strokeWidth.toStringAsFixed(1),
                        onChanged: (v) => setState(() => _strokeWidth = v),
                        onSave: DanmakuSettingService.setStrokeWidth,
                        last: true,
                      ),
                    ],
                  ),
                  _sectionLabel('显示', context),
                  _SectionCard(
                    children: [
                      _sliderTile(
                        context,
                        icon: Icons.aspect_ratio_rounded,
                        label: '弹幕区域',
                        value: _area,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        display: '${(_area * 100).round()}%',
                        onChanged: (v) => setState(() => _area = v),
                        onSave: DanmakuSettingService.setArea,
                      ),
                      _divider(context),
                      _sliderTile(
                        context,
                        icon: Icons.timer_outlined,
                        label: '持续时间',
                        value: _duration,
                        min: 2,
                        max: 16,
                        divisions: 14,
                        display: '${_duration.round()}s',
                        onChanged: (v) => setState(() => _duration = v.roundToDouble()),
                        onSave: (v) => DanmakuSettingService.setDuration(v.roundToDouble()),
                        last: true,
                      ),
                    ],
                  ),
                  _sectionLabel('类型', context),
                  _SectionCard(
                    children: [
                      SwitchListTile(
                        dense: true,
                        secondary: Icon(Icons.vertical_align_top_rounded, size: 20, color: cs.onSurfaceVariant),
                        title: const Text('顶部弹幕'),
                        value: _showTop,
                        onChanged: (v) {
                          setState(() => _showTop = v);
                          DanmakuSettingService.setShowTop(v);
                        },
                      ),
                      _divider(context),
                      SwitchListTile(
                        dense: true,
                        secondary: Icon(Icons.vertical_align_bottom_rounded, size: 20, color: cs.onSurfaceVariant),
                        title: const Text('底部弹幕'),
                        value: _showBottom,
                        onChanged: (v) {
                          setState(() => _showBottom = v);
                          DanmakuSettingService.setShowBottom(v);
                        },
                      ),
                      _divider(context),
                      SwitchListTile(
                        dense: true,
                        secondary: Icon(Icons.swap_horiz_rounded, size: 20, color: cs.onSurfaceVariant),
                        title: const Text('滚动弹幕'),
                        value: _showScroll,
                        onChanged: (v) {
                          setState(() => _showScroll = v);
                          DanmakuSettingService.setShowScroll(v);
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _sectionLabel(String title, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
    );
  }

  Widget _sliderTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String display,
    required void Function(double) onChanged,
    required Future<void> Function(double) onSave,
    bool last = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.onSurface.withValues(alpha: 0.12),
              thumbColor: cs.primary,
              overlayColor: cs.primary.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onSave,
            ),
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
