import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/video_play/service/hardware_decode_service.dart';

class HardwareDecodePage extends StatefulWidget {
  const HardwareDecodePage({super.key});

  @override
  State<HardwareDecodePage> createState() => _HardwareDecodePageState();
}

class _HardwareDecodePageState extends State<HardwareDecodePage> {
  final HardwareDecodeService _hwService = HardwareDecodeService();

  bool _enabled = true;
  HwDecoder _decoder = HwDecoder.auto;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await _hwService.getEnabled();
    final decoder = await _hwService.getDecoder();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _decoder = decoder;
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    await _hwService.setEnabled(value);
    setState(() => _enabled = value);
  }

  Future<void> _setDecoder(HwDecoder decoder) async {
    await _hwService.setDecoder(decoder);
    setState(() => _decoder = decoder);
  }

  String get _platformLabel {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return '当前平台';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final decoders = HwDecoder.platformDecoders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('硬件解码'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 平台提示
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '当前平台：$_platformLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),

                // 硬件解码总开关
                _SectionCard(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.memory_outlined,
                        color: _enabled ? cs.primary : cs.onSurfaceVariant,
                      ),
                      title: const Text('启用硬件解码'),
                      subtitle: const Text('关闭后使用纯软件解码，性能较低但兼容性最佳'),
                      value: _enabled,
                      onChanged: _setEnabled,
                    ),
                  ],
                ),

                // 解码器选择（仅开启时可操作）
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    '解码器',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                _SectionCard(
                  children: List.generate(decoders.length, (i) {
                    final d = decoders[i];
                    final selected = _decoder == d;
                    final isLast = i == decoders.length - 1;
                    return Column(
                      children: [
                        ListTile(
                          enabled: _enabled,
                          leading: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected && _enabled
                                    ? cs.primary
                                    : cs.outline,
                                width: selected && _enabled ? 6 : 2,
                              ),
                            ),
                          ),
                          title: Text(
                            d.label,
                            style: TextStyle(
                              fontWeight: selected && _enabled
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected && _enabled
                                  ? cs.primary
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            d.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: _enabled
                                  ? cs.onSurfaceVariant
                                  : cs.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                          ),
                          trailing: selected && _enabled
                              ? Icon(Icons.check_circle,
                                  color: cs.primary, size: 18)
                              : null,
                          onTap: _enabled ? () => _setDecoder(d) : null,
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 56,
                            endIndent: 16,
                            color: cs.outlineVariant,
                          ),
                      ],
                    );
                  }),
                ),

                // 说明
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '修改设置后，重新进入视频页面生效。\n若出现花屏或崩溃，请尝试切换解码器或关闭硬件解码。',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
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
