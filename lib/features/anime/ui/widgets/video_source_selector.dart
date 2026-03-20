import 'package:flutter/material.dart';
import 'package:mikomi/features/video/data/repositories/video_source_repository.dart';
import 'package:mikomi/features/settings/video_settings/service/plugin_manager_service.dart';

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
  final VideoPluginManager _pluginManager = VideoPluginManager();
  final Map<String, bool?> _sourceAvailability = {};
  final Map<String, int> _sourceEpisodeCount = {};
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initSources();
  }

  void _initSources() {
    // 去重
    final uniqueSources = <String, VideoSource>{};
    for (var source in widget.sources) {
      uniqueSources[source.name] = source;
    }
    _sources = uniqueSources.values.toList();

    // 根据VideoPluginManager中的顺序排序
    _sortSourcesByPluginOrder();

    _tabController = TabController(length: _sources.length, vsync: this);

    if (widget.animeTitle != null && widget.animeTitle!.isNotEmpty) {
      _checkSourcesAvailability();
    }
  }

  /// 根据VideoPluginManager中的插件顺序排序视频源
  void _sortSourcesByPluginOrder() {
    final plugins = _pluginManager.plugins;
    final pluginOrder = <String, int>{};

    // 建立插件名称到索引的映射
    for (int i = 0; i < plugins.length; i++) {
      pluginOrder[plugins[i].name] = i;
    }

    // 按照插件顺序排序,未在插件列表中的排在最后
    _sources.sort((a, b) {
      final aOrder = pluginOrder[a.name] ?? 999;
      final bOrder = pluginOrder[b.name] ?? 999;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }

      // 顺序相同时按名称排序
      return a.name.compareTo(b.name);
    });
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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '选择视频源',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 视频源标签
          TabBar(
            controller: _tabController,
            isScrollable: true,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabAlignment: TabAlignment.start,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
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
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
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
    final isChecking = hasResource == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 资源状态卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '视频源',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isChecking
                            ? Colors.grey.withValues(alpha: 0.1)
                            : hasResource
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isChecking
                            ? '检查中'
                            : hasResource
                            ? '可用'
                            : '不可用',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isChecking
                              ? Colors.grey
                              : hasResource
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  source.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (!isChecking && hasResource) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.video_collection_outlined,
                        size: 16,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '共 $episodeCount 集',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 观看按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (hasResource ?? false) && !isChecking
                  ? () => widget.onSourceSelected(source)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Theme.of(
                  context,
                ).disabledColor.withValues(alpha: 0.1),
                disabledForegroundColor: Theme.of(context).disabledColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isChecking
                        ? Icons.hourglass_empty
                        : hasResource
                        ? Icons.play_arrow
                        : Icons.error_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isChecking
                        ? '检查中...'
                        : hasResource
                        ? '立即观看'
                        : '暂无资源',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isChecking && !hasResource) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.red.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '该视频源暂无此番剧资源',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
