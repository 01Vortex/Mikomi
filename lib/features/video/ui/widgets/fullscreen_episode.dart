import 'package:flutter/material.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
import 'package:mikomi/shared/widgets/scrolling_text.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class FullscreenEpisodeSelector extends StatefulWidget {
  final List<Episode> episodes;
  final int currentEpisode;
  final Function(Episode) onEpisodeSelected;
  final bool isLoading;
  final bool isDescending;
  final VoidCallback onToggleSort;

  const FullscreenEpisodeSelector({
    super.key,
    required this.episodes,
    required this.currentEpisode,
    required this.onEpisodeSelected,
    this.isLoading = false,
    this.isDescending = false,
    required this.onToggleSort,
  });

  @override
  State<FullscreenEpisodeSelector> createState() =>
      _FullscreenEpisodeSelectorState();
}

class _FullscreenEpisodeSelectorState extends State<FullscreenEpisodeSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentEpisode());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentEpisode() {
    if (!_scrollController.hasClients) return;
    final episodes = widget.isDescending
        ? widget.episodes.reversed.toList()
        : widget.episodes;
    final index = episodes.indexWhere((ep) => ep.number == widget.currentEpisode);
    if (index < 0) return;

    // 每行3个，每个约 56px 高度（childAspectRatio=2.0, crossAxisSpacing=12, padding=16）
    const crossAxisCount = 3;
    const itemHeight = 56.0;
    const mainAxisSpacing = 12.0;
    const padding = 16.0;
    final row = index ~/ crossAxisCount;
    final offset = padding + row * (itemHeight + mainAxisSpacing);
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('========== 全屏选集面板 ==========');
    debugPrint('剧集数量: ${widget.episodes.length}');
    debugPrint('当前集数: ${widget.currentEpisode}');
    debugPrint('是否加载中: ${widget.isLoading}');
    debugPrint('==================================');

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: context.colors.surface.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.isLoading && widget.episodes.isEmpty
                  ? _buildLoadingSkeleton()
                  : _buildEpisodeList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '选集',
            style: TextStyle(
              color: context.colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onToggleSort,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isDescending
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        size: 14,
                        color: context.colors.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.isDescending ? '倒序' : '正序',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: false).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: context.colors.onSurface,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 12,
      itemBuilder: (context, index) => const SkeletonEpisodeCard(),
    );
  }

  Widget _buildEpisodeList() {
    if (widget.episodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: context.colors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无剧集',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final sortedEpisodes = widget.isDescending
        ? widget.episodes.reversed.toList()
        : widget.episodes;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: sortedEpisodes.length,
      itemBuilder: (context, index) {
        final episode = sortedEpisodes[index];
        final isCurrent = episode.number == widget.currentEpisode;

        return _buildEpisodeCard(episode, isCurrent);
      },
    );
  }

  Widget _buildEpisodeCard(Episode episode, bool isCurrent) {
    return GestureDetector(
      onTap: () {
        widget.onEpisodeSelected(episode);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent
              ? context.colors.primaryLight
              : context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? context.colors.primary
                : context.colors.outlineVariant,
            width: isCurrent ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '第${episode.number}集',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent
                    ? context.colors.primary
                    : context.colors.textPrimary,
              ),
            ),
            if (episode.title != null && episode.title!.isNotEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ScrollingText(
                  text: episode.title!,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textSecondary,
                  ),
                  height: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
