import 'package:flutter/material.dart';
import 'package:mikomi/features/video/origin/bt/rss_bt_resolver.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_source_service.dart';

enum SourceType { web, bt }

class BtEpisodeInfo {
  final int number;
  final String title;
  final String magnet;
  const BtEpisodeInfo({required this.number, required this.title, required this.magnet});
}

class VideoSource {
  final String name;
  final SourceType type;
  final Map<String, dynamic>? config;
  final BtEpisodeInfo? btEpisode;

  const VideoSource({
    required this.name,
    this.type = SourceType.web,
    this.config,
    this.btEpisode,
  });
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
  final VideoEpisodeService _videoService = VideoEpisodeService();
  final VideoSourceService _sourceService = VideoSourceService();
  final Map<String, bool?> _sourceAvailability = {};
  final Map<String, int> _sourceEpisodeCount = {};
  final Map<String, List<RssEpisode>> _btEpisodes = {};
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _initSources();
  }

  void _initSources() {
    final uniqueSources = <String, VideoSource>{};
    for (var source in widget.sources) {
      uniqueSources[source.name] = source;
    }
    _sources = uniqueSources.values.toList();
    _sortSourcesByPluginOrder();
    _tabController = TabController(length: _sources.length, vsync: this);
    if (widget.animeTitle != null && widget.animeTitle!.isNotEmpty) {
      _checkSourcesAvailability();
    }
  }

  void _sortSourcesByPluginOrder() {
    final plugins = _sourceService.getAvailableSources();
    final pluginOrder = <String, int>{};
    for (int i = 0; i < plugins.length; i++) {
      pluginOrder[plugins[i].name] = i;
    }
    _sources.sort((a, b) {
      final aOrder = pluginOrder[a.name] ?? 999;
      final bOrder = pluginOrder[b.name] ?? 999;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
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

    for (var source in _sources) {
      _sourceAvailability[source.name] = null;
      _sourceEpisodeCount[source.name] = 0;
    }

    for (var source in _sources) {
      if (source.type == SourceType.web) {
        _checkWebSource(source);
      } else {
        // BT 源不检查剧集（RSS 搜索在不同阶段进行）
        _sourceAvailability[source.name] = true;
      }
    }
    setState(() => _isChecking = false);
  }

  Future<void> _checkWebSource(VideoSource source) async {
    try {
      final episodes = await _videoService
          .loadEpisodes(
            sourceName: source.name,
            animeTitle: widget.animeTitle,
            animeName: null,
            bangumiId: null,
          )
          .timeout(const Duration(seconds: 60), onTimeout: () => []);
      if (mounted) {
        setState(() {
          _sourceAvailability[source.name] = episodes.isNotEmpty;
          _sourceEpisodeCount[source.name] = episodes.length;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sourceAvailability[source.name] = false;
          _sourceEpisodeCount[source.name] = 0;
        });
      }
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
          _buildDragHandle(context),
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildTabBar(context),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          _buildTabView(context),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.video_library_outlined,
              size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('选择视频源',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/plugin_manage');
            },
            child: Icon(Icons.settings_outlined,
                size: 20, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      tabAlignment: TabAlignment.start,
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
      indicatorColor: Theme.of(context).colorScheme.primary,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
      tabs: _sources.map((source) => _buildTab(source)).toList(),
    );
  }

  Widget _buildTab(VideoSource source) {
    final hasResource = _sourceAvailability[source.name];
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (source.type == SourceType.bt)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.swap_vert, size: 14,
                  color: _sourceColor(source, hasResource)),
            ),
          Text(source.name),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _sourceColor(source, hasResource),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Color _sourceColor(VideoSource source, bool? hasResource) {
    if (source.type == SourceType.bt) return Colors.blue;
    return hasResource == true
        ? Colors.green
        : hasResource == false
            ? Colors.red
            : Colors.grey;
  }

  Widget _buildTabView(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: TabBarView(
        controller: _tabController,
        children: _sources.map((s) => _buildSourceContent(s)).toList(),
      ),
    );
  }

  Widget _buildSourceContent(VideoSource source) {
    if (source.type == SourceType.bt) return _buildBtContent(source);
    return _buildWebContent(source);
  }

  // ── Web 源内容 ──

  Widget _buildWebContent(VideoSource source) {
    final hasResource = _sourceAvailability[source.name];
    final episodeCount = _sourceEpisodeCount[source.name] ?? 0;
    final isChecking = hasResource == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(source, isChecking, hasResource, episodeCount),
          const SizedBox(height: 20),
          _buildActionButton(source, isChecking, hasResource,
              icon: Icons.play_arrow, label: '立即观看'),
        ],
      ),
    );
  }

  // ── BT 源内容 ──

  Widget _buildBtContent(VideoSource source) {
    final episodes = _btEpisodes[source.name];
    final searchUrl =
        source.config?['searchConfig']?['searchUrl'] as String? ?? '';
    final displayUrl =
        searchUrl.replaceAll('{keyword}', widget.animeTitle ?? '...');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BT 信息卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context).dividerColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.swap_vert, size: 16, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text('BT 磁力源',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('BT',
                        style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(source.name,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.rss_feed, size: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(displayUrl,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                ]),
                if (episodes != null) ...[
                  const SizedBox(height: 8),
                  Text('共 ${episodes.length} 集',
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 剧集列表 或 搜索按钮
          if (episodes == null)
            _buildActionButton(source, false, true,
                icon: Icons.search, label: '搜索磁力',
                onTapOverride: () => _loadBtEpisodes(source))
          else if (episodes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('未找到剧集', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...episodes.map((ep) => _buildBtEpisodeTile(source, ep)),
        ],
      ),
    );
  }

  Widget _buildBtEpisodeTile(VideoSource source, RssEpisode ep) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Text('${ep.number}',
              style: const TextStyle(fontSize: 12, color: Colors.blue)),
        ),
        title: Text(ep.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13)),
        onTap: () => widget.onSourceSelected(VideoSource(
          name: source.name,
          type: SourceType.bt,
          config: source.config,
          btEpisode: BtEpisodeInfo(
            number: ep.number, title: ep.title, magnet: ep.magnet,
          ),
        )),
      ),
    );
  }

  Future<void> _loadBtEpisodes(VideoSource source) async {
    setState(() {});
    try {
      final resolver = _sourceService.btResolver;
      final episodes = await resolver.fetchEpisodes(source
        ..config?['keyword'] = widget.animeTitle);
      if (mounted) {
        setState(() => _btEpisodes[source.name] = episodes);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _btEpisodes[source.name] = []);
      }
    }
  }

  // ── 共享组件 ──

  Widget _buildStatusCard(VideoSource source, bool isChecking,
      bool? hasResource, int episodeCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('视频源',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
              const Spacer(),
              _buildStatusBadge(isChecking, hasResource),
            ],
          ),
          const SizedBox(height: 12),
          Text(source.name,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
          if (!isChecking && hasResource == true) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.video_collection_outlined, size: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text('共 $episodeCount 集',
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isChecking, bool? hasResource) {
    final (label, bg, fg) = isChecking
        ? ('检查中', Colors.grey.withValues(alpha: 0.1), Colors.grey)
        : hasResource == true
            ? ('可用', Colors.green.withValues(alpha: 0.1), Colors.green)
            : ('不可用', Colors.red.withValues(alpha: 0.1), Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
    );
  }

  Widget _buildActionButton(VideoSource source, bool isChecking,
      bool? hasResource, {required IconData icon, required String label, VoidCallback? onTapOverride}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: (hasResource ?? false) && !isChecking
            ? (onTapOverride ?? (() => widget.onSourceSelected(source)))
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Theme.of(context).disabledColor.withValues(alpha: 0.1),
          disabledForegroundColor: Theme.of(context).disabledColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isChecking ? Icons.hourglass_empty : icon, size: 20),
            const SizedBox(width: 8),
            Text(
              isChecking ? '检查中...' : hasResource == true ? label : '暂无资源',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
