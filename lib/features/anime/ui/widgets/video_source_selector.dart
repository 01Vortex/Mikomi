import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

class VideoSource {
  final String name;
  final int latency;
  final bool isAvailable;

  VideoSource({
    required this.name,
    required this.latency,
    this.isAvailable = true,
  });
}

class VideoSourceSelector extends StatefulWidget {
  final List<VideoSource> sources;
  final Function(VideoSource) onSourceSelected;

  const VideoSourceSelector({
    super.key,
    required this.sources,
    required this.onSourceSelected,
  });

  @override
  State<VideoSourceSelector> createState() => _VideoSourceSelectorState();
}

class _VideoSourceSelectorState extends State<VideoSourceSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 去重并按名称排序
    final uniqueSources = <String, VideoSource>{};
    for (var source in widget.sources) {
      uniqueSources[source.name] = source;
    }
    final sortedSources = uniqueSources.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    _tabController = TabController(length: sortedSources.length, vsync: this);
    _sources = sortedSources;
  }

  late final List<VideoSource> _sources;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getLatencyColor(int latency) {
    if (latency < 100) {
      return Colors.green;
    } else if (latency < 300) {
      return Colors.orange;
    } else {
      return Colors.red;
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
                        color: source.isAvailable
                            ? _getLatencyColor(source.latency)
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '延迟:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(
                '${source.latency}ms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getLatencyColor(source.latency),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: source.isAvailable
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  source.isAvailable ? '可用' : '不可用',
                  style: TextStyle(
                    fontSize: 12,
                    color: source.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: source.isAvailable
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
              child: const Text('开始播放', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
