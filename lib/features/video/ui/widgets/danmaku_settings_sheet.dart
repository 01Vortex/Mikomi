import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:mikomi/features/video/services/danmaku_settings_service.dart';

class DanmakuSettingsSheet extends StatefulWidget {
  final DanmakuController? danmakuController;
  final void Function(DanmakuConfig config)? onConfigChanged;

  const DanmakuSettingsSheet({
    super.key,
    this.danmakuController,
    this.onConfigChanged,
  });

  @override
  State<DanmakuSettingsSheet> createState() => _DanmakuSettingsSheetState();
}

class _DanmakuSettingsSheetState extends State<DanmakuSettingsSheet>
    with SingleTickerProviderStateMixin {
  late double _fontSize;
  late double _opacity;
  late double _area;
  late double _duration;
  late double _strokeWidth;
  late bool _showTop;
  late bool _showBottom;
  late bool _showScroll;
  bool _loaded = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadConfig();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = await DanmakuSettingsService.loadAll();
    if (!mounted) return;
    setState(() {
      _fontSize = config.fontSize;
      _opacity = config.opacity;
      _area = config.area;
      _duration = config.duration;
      _strokeWidth = config.strokeWidth;
      _showTop = config.showTop;
      _showBottom = config.showBottom;
      _showScroll = config.showScroll;
      _loaded = true;
    });
    _animController.forward();
  }

  DanmakuConfig get _currentConfig => DanmakuConfig(
        fontSize: _fontSize,
        opacity: _opacity,
        area: _area,
        duration: _duration,
        strokeWidth: _strokeWidth,
        showTop: _showTop,
        showBottom: _showBottom,
        showScroll: _showScroll,
      );

  void _apply() {
    final ctrl = widget.danmakuController;
    if (ctrl != null) {
      ctrl.updateOption(ctrl.option.copyWith(
        fontSize: _fontSize,
        opacity: _opacity,
        area: _area,
        duration: _duration,
        strokeWidth: _strokeWidth,
        hideTop: !_showTop,
        hideBottom: !_showBottom,
        hideScroll: !_showScroll,
      ));
    }
    widget.onConfigChanged?.call(_currentConfig);
  }
// PART2

  Widget _pill(String label) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.8,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Column(children: children),
      );

  Widget _sliderRow({
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(display, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                )),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min, max: max, divisions: divisions,
            onChanged: (v) { setState(() => onChanged(v)); _apply(); },
            onChangeEnd: (v) => onSave(v),
          ),
        ),
        if (!last) Divider(height: 1, indent: 16, endIndent: 16,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
      ],
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String label,
    required bool value,
    required void Function(bool) onChanged,
    required Future<void> Function(bool) onSave,
    bool last = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SwitchListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            secondary: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            value: value,
            onChanged: (v) { setState(() => onChanged(v)); _apply(); onSave(v); },
          ),
        ),
        if (!last) Divider(height: 1, indent: 16, endIndent: 16,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08)),
      ],
    );
  }
// PART3

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.88,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    width: 32, height: 3,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 12),
                  child: Row(
                    children: [
                      const Text('弹幕设置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('完成', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: !_loaded
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.only(bottom: 32),
                            children: [
                              Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 6), child: _pill('样式')),
                              _card([
                                _sliderRow(icon: Icons.text_fields_rounded, label: '字体大小',
                                    value: _fontSize, min: 10, max: 32,
                                    display: '${_fontSize.floor()}',
                                    onChanged: (v) => _fontSize = v.floorToDouble(),
                                    onSave: (v) => DanmakuSettingsService.setFontSize(v.floorToDouble())),
                                _sliderRow(icon: Icons.opacity_rounded, label: '不透明度',
                                    value: _opacity, min: 0.1, max: 1.0, divisions: 18,
                                    display: '${(_opacity * 100).round()}%',
                                    onChanged: (v) => _opacity = v,
                                    onSave: (v) => DanmakuSettingsService.setOpacity(v)),
                                _sliderRow(icon: Icons.border_color_rounded, label: '描边粗细',
                                    value: _strokeWidth, min: 0.0, max: 3.0, divisions: 30,
                                    display: _strokeWidth.toStringAsFixed(1),
                                    onChanged: (v) => _strokeWidth = v,
                                    onSave: (v) => DanmakuSettingsService.setStrokeWidth(v),
                                    last: true),
                              ]),
                              const SizedBox(height: 16),
                              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 6), child: _pill('显示')),
                              _card([
                                _sliderRow(icon: Icons.aspect_ratio_rounded, label: '弹幕区域',
                                    value: _area, min: 0.1, max: 1.0, divisions: 9,
                                    display: '${(_area * 100).round()}%',
                                    onChanged: (v) => _area = v,
                                    onSave: (v) => DanmakuSettingsService.setArea(v)),
                                _sliderRow(icon: Icons.timer_outlined, label: '持续时间',
                                    value: _duration, min: 2, max: 16, divisions: 14,
                                    display: '${_duration.round()}s',
                                    onChanged: (v) => _duration = v.roundToDouble(),
                                    onSave: (v) => DanmakuSettingsService.setDuration(v.roundToDouble()),
                                    last: true),
                              ]),
                              const SizedBox(height: 16),
                              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 6), child: _pill('类型')),
                              _card([
                                _switchRow(icon: Icons.vertical_align_top_rounded, label: '顶部弹幕',
                                    value: _showTop, onChanged: (v) => _showTop = v,
                                    onSave: DanmakuSettingsService.setShowTop),
                                _switchRow(icon: Icons.vertical_align_bottom_rounded, label: '底部弹幕',
                                    value: _showBottom, onChanged: (v) => _showBottom = v,
                                    onSave: DanmakuSettingsService.setShowBottom),
                                _switchRow(icon: Icons.swap_horiz_rounded, label: '滚动弹幕',
                                    value: _showScroll, onChanged: (v) => _showScroll = v,
                                    onSave: DanmakuSettingsService.setShowScroll, last: true),
                              ]),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 全屏右侧弹幕设置侧边栏 ─────────────────────────────────────────

class DanmakuSettingsSidebar extends StatefulWidget {
  final VoidCallback? onClose;
  const DanmakuSettingsSidebar({super.key, this.onClose});
  @override
  State<DanmakuSettingsSidebar> createState() => _DanmakuSettingsSidebarState();
}

class _DanmakuSettingsSidebarState extends State<DanmakuSettingsSidebar> {
  late double _fontSize;
  late double _opacity;
  late double _area;
  late double _duration;
  late double _strokeWidth;
  late bool _showTop;
  late bool _showBottom;
  late bool _showScroll;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await DanmakuSettingsService.loadAll();
    if (!mounted) return;
    setState(() {
      _fontSize = config.fontSize;
      _opacity = config.opacity;
      _area = config.area;
      _duration = config.duration;
      _strokeWidth = config.strokeWidth;
      _showTop = config.showTop;
      _showBottom = config.showBottom;
      _showScroll = config.showScroll;
      _loaded = true;
    });
  }

  void _save() {
    DanmakuSettingsService.setFontSize(_fontSize);
    DanmakuSettingsService.setOpacity(_opacity);
    DanmakuSettingsService.setArea(_area);
    DanmakuSettingsService.setDuration(_duration);
    DanmakuSettingsService.setStrokeWidth(_strokeWidth);
    DanmakuSettingsService.setShowTop(_showTop);
    DanmakuSettingsService.setShowBottom(_showBottom);
    DanmakuSettingsService.setShowScroll(_showScroll);
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
        child: Text(text,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.4),
            )),
      );

  Widget _sliderItem({
    required IconData icon, required String label,
    required double value, required double min, required double max,
    int? divisions, required String display,
    required void Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(display, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white.withValues(alpha: 0.9),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: value.clamp(min, max), min: min, max: max, divisions: divisions,
              onChanged: (v) { setState(() => onChanged(v)); _save(); },
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchItem({
    required IconData icon, required String label,
    required bool value, required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
          const Spacer(),
          Transform.scale(
            scale: 0.75,
            alignment: Alignment.centerRight,
            child: Switch(
              value: value,
              onChanged: (v) { setState(() => onChanged(v)); _save(); },
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.4),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
          border: Border(
            left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
                child: Row(
                  children: [
                    const Text('弹幕设置',
                        style: TextStyle(color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !_loaded
                    ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.6)))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          _sectionLabel('样式'),
                          _sliderItem(icon: Icons.text_fields_rounded, label: '字体大小',
                              value: _fontSize, min: 10, max: 32,
                              display: '${_fontSize.floor()}',
                              onChanged: (v) => _fontSize = v.floorToDouble()),
                          _sliderItem(icon: Icons.opacity_rounded, label: '不透明度',
                              value: _opacity, min: 0.1, max: 1.0, divisions: 18,
                              display: '${(_opacity * 100).round()}%',
                              onChanged: (v) => _opacity = v),
                          _sliderItem(icon: Icons.border_color_rounded, label: '描边粗细',
                              value: _strokeWidth, min: 0.0, max: 3.0, divisions: 30,
                              display: _strokeWidth.toStringAsFixed(1),
                              onChanged: (v) => _strokeWidth = v),
                          _sectionLabel('显示'),
                          _sliderItem(icon: Icons.aspect_ratio_rounded, label: '弹幕区域',
                              value: _area, min: 0.1, max: 1.0, divisions: 9,
                              display: '${(_area * 100).round()}%',
                              onChanged: (v) => _area = v),
                          _sliderItem(icon: Icons.timer_outlined, label: '持续时间',
                              value: _duration, min: 2, max: 16, divisions: 14,
                              display: '${_duration.round()}s',
                              onChanged: (v) => _duration = v.roundToDouble()),
                          _sectionLabel('类型'),
                          _switchItem(icon: Icons.vertical_align_top_rounded, label: '顶部弹幕',
                              value: _showTop, onChanged: (v) => _showTop = v),
                          _switchItem(icon: Icons.vertical_align_bottom_rounded, label: '底部弹幕',
                              value: _showBottom, onChanged: (v) => _showBottom = v),
                          _switchItem(icon: Icons.swap_horiz_rounded, label: '滚动弹幕',
                              value: _showScroll, onChanged: (v) => _showScroll = v),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



