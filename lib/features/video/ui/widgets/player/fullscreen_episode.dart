import 'package:flutter/material.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/shared/skeleton.dart';
import 'package:mikomi/shared/theme_extensions.dart';

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

class _FullscreenEpisodeSelectorState
    extends State<FullscreenEpisodeSelector> {
  static const int _crossAxisCount = 3;
  static const double _itemHeight = 52.0;
  static const double _mainAxisSpacing = 10.0;
  static const double _gridTopPadding = 4.0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentEpisodeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToCurrentEpisode());
  }

  @override
  void didUpdateWidget(covariant FullscreenEpisodeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRescroll =
        oldWidget.currentEpisode != widget.currentEpisode ||
        oldWidget.isDescending != widget.isDescending ||
        oldWidget.episodes.length != widget.episodes.length;
    if (shouldRescroll) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollToCurrentEpisode());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentEpisode() {
    final currentContext = _currentEpisodeKey.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    if (!_scrollController.hasClients) return;

    final episodes = widget.isDescending
        ? widget.episodes.reversed.toList()
        : widget.episodes;
    final index = episodes.indexWhere((ep) => ep.number == widget.currentEpisode);
    if (index < 0) return;

    final row = index ~/ _crossAxisCount;
    final itemExtent = _itemHeight + _mainAxisSpacing;
    final viewport = _scrollController.position.viewportDimension;
    final targetCenter = _gridTopPadding + row * itemExtent + (_itemHeight / 2);
    final desiredOffset = targetCenter - (viewport / 2);
    final clampedOffset = desiredOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 380,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(24)),
          border: Border(
            left: BorderSide(
              color: Colors.black.withValues(alpha: 0.06),
            ),
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          children: [
            const Spacer(),
            // 排序按钮
            GestureDetector(
              onTap: widget.onToggleSort,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isDescending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      size: 13,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.isDescending ? '倒序' : '正序',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 关闭按钮
            GestureDetector(
              onTap: () => Navigator.of(context, rootNavigator: false).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.black54,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 16,
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
              size: 48,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无剧集',
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.35),
                fontSize: 13,
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: sortedEpisodes.length,
      itemBuilder: (context, index) {
        final episode = sortedEpisodes[index];
        final isCurrent = episode.number == widget.currentEpisode;
        return KeyedSubtree(
          key: isCurrent ? _currentEpisodeKey : null,
          child: _buildEpisodeCard(episode, isCurrent),
        );
      },
    );
  }

  Widget _buildEpisodeCard(Episode episode, bool isCurrent) {
    return GestureDetector(
      onTap: () => widget.onEpisodeSelected(episode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isCurrent
              ? context.colors.primary.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCurrent
                ? context.colors.primary.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.08),
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '第${episode.number}集',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent
                ? context.colors.primary
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}
