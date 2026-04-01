import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/video_play/service/video_renderer_service.dart';

class VideoRendererPage extends StatefulWidget {
  const VideoRendererPage({super.key});

  @override
  State<VideoRendererPage> createState() => _VideoRendererPageState();
}

class _VideoRendererPageState extends State<VideoRendererPage> {
  final VideoRendererService _service = VideoRendererService();

  VideoRenderer _renderer = VideoRenderer.auto;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final renderer = await _service.getRenderer();
    if (!mounted) return;
    setState(() {
      _renderer = renderer;
      _loading = false;
    });
  }

  Future<void> _setRenderer(VideoRenderer renderer) async {
    await _service.setRenderer(renderer);
    if (!mounted) return;
    setState(() => _renderer = renderer);
  }

  String get _platformLabel {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return '当前平台';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final renderers = VideoRenderer.platformRenderers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('视频渲染器'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
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
                _SectionCard(
                  children: List.generate(renderers.length, (i) {
                    final item = renderers[i];
                    final selected = _renderer == item;
                    final isLast = i == renderers.length - 1;

                    return Column(
                      children: [
                        ListTile(
                          leading: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? cs.primary : cs.outline,
                                width: selected ? 6 : 2,
                              ),
                            ),
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected ? cs.primary : null,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          trailing: selected
                              ? Icon(Icons.check_circle,
                                  color: cs.primary, size: 18)
                              : null,
                          onTap: () => _setRenderer(item),
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
                            '修改设置后，重新进入视频页面生效。\n若出现黑屏或卡顿，请切换其他渲染器。',
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
