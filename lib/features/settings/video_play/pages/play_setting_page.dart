import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';

class VideoBasisPage extends StatefulWidget {
  const VideoBasisPage({super.key});

  @override
  State<VideoBasisPage> createState() => _VideoBasisPageState();
}

class _VideoBasisPageState extends State<VideoBasisPage> {
  final PlaySettingsService _service = PlaySettingsService();

  bool _autoPlayNext = true;
  double _playSpeed = 1.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final autoPlayNext = await _service.getAutoPlayNext();
    final playSpeed = await _service.getPlaySpeed();
    if (!mounted) return;
    setState(() {
      _autoPlayNext = autoPlayNext;
      _playSpeed = playSpeed;
      _loading = false;
    });
  }

  Future<void> _setAutoPlayNext(bool value) async {
    await _service.setAutoPlayNext(value);
    setState(() => _autoPlayNext = value);
  }

  Future<void> _setPlaySpeed(double value) async {
    await _service.setPlaySpeed(value);
    setState(() => _playSpeed = value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('播放基础设置'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // 自动连播
                _SectionCard(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.skip_next_outlined,
                        color: _autoPlayNext ? cs.primary : cs.onSurfaceVariant,
                      ),
                      title: const Text('自动连播'),
                      subtitle: const Text('当前视频播放完毕后自动播放下一集'),
                      value: _autoPlayNext,
                      onChanged: _setAutoPlayNext,
                    ),
                  ],
                ),

                // 默认倍速
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    '默认倍速',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                _SectionCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '倍速',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_playSpeed}x',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              activeTrackColor: cs.primary,
                              inactiveTrackColor:
                                  cs.onSurface.withValues(alpha: 0.12),
                              thumbColor: cs.primary,
                              overlayColor:
                                  cs.primary.withValues(alpha: 0.15),
                            ),
                            child: Slider(
                              value: _playSpeed,
                              min: 0.5,
                              max: 2.0,
                              divisions: 6,
                              label: '${_playSpeed}x',
                              onChanged: _setPlaySpeed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0.5x',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '2.0x',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            '这些设置将应用于新打开的视频。\n已在播放的视频不会受到影响。',
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
