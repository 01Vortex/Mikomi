import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/data/repositories/video_source_repository.dart';

class VideoSource {
  final String name;

  VideoSource({required this.name});
}

class VideoSourceSelector extends StatefulWidget {
  final List<VideoSource> sources;
  final Function(VideoSource) onSourceSelected;
  final String? animeTitle;

  const VideoSourceSelector({
    super.key,
    required this.sources,
    required this.onSourceSelected,
    this.animeTitle,
  });

  @override
  State<VideoSourceSelector> createState() => _VideoSourceSelectorState();
}

class _VideoSourceSelectorState extends State<VideoSourceSelector>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<VideoSource> _sources;
  final VideoSourceRepository _videoSourceRepo = VideoSourceRepository();
  final Map<String, bool?> _sourceAvailability = {};
  final Map<String, int> _sourceEpisodeCount = {};
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // 去重并按名称排序
    final uniqueSources = <String, VideoSource>{};
    for (var source in widget.sources) {
      uniqueSources[source.name] = source;
    }
    _sources = uniqueSources.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    _tabController = TabController(length: _sources.length, vsync: this);

    if (widget.animeTitle != null && widget.animeTitle!.isNotEmpty) {
      _checkSourcesAvailability();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkSourcesAvailability() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    // 初始化所有视频源状态为pending
    for (var source in _sources) {
      _sourceAvailability[source.name] = null;
      _sourceEpisodeCount[source.name] = 0;
    }

    // 并发检查所有视频源
    final futures = _sources.map((source) async {
      try {
        debugPrint('[${source.name}] 开始检查视频源');
        final episodes = await _videoSourceRepo
            .searchAndGetEpisodes(widget.animeTitle!, source.name)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () {
                debugPrint('[${source.name}] 检查超时');
                return [];
              },
            );

        debugPrint('[${source.name}] 检查完成: ${episodes.length} 集');

        if (mounted) {
          setState(() {
            _sourceAvailability[source.name] = episodes.isNotEmpty;
            _sourceEpisodeCount[source.name] = episodes.length;
            debugPrint(
              '[${source.name}] 状态已更新: hasResource=${episodes.isNotEmpty}, count=${episodes.length}',
            );
          });
        }
      } catch (e, stackTrace) {
        debugPrint('[${source.name}] 检查失败: $e');
        debugPrint('[${source.name}] 堆栈: $stackTrace');
        if (mounted) {
          setState(() {
            _sourceAvailability[source.name] = false;
            _sourceEpisodeCount[source.name] = 0;
          });
        }
      }
    });

    // 等待所有检查完成
    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
            ),
            tabs: _sources.map((source) {
              final hasResource = _sourceAvailability[source.name];
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(source.name),
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hasResource == true
                            ? Colors.green
                            : hasResource == false
                            ? Colors.red
                            : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const Divider(height: 1),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TabBarView(
              controller: _tabController,
              children: _sources.map((source) {
                return _buildSourceContent(source);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceContent(VideoSource source) {
    final hasResource = _sourceAvailability[source.name];
    final episodeCount = _sourceEpisodeCount[source.name] ?? 0;
    // 如果hasResource为null,说明正在检查中
    final isChecking = hasResource == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isChecking)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  '正在检查资源...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  hasResource ? Icons.check_circle : Icons.cancel,
                  color: hasResource ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  hasResource ? '找到 $episodeCount 集' : '未找到资源',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: hasResource ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (hasResource ?? false) && !isChecking
                  ? () {
                      widget.onSourceSelected(source);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('立即观看', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
