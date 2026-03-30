import 'package:flutter/material.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/shared/widgets/skeleton.dart';
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

class _FullscreenEpisodeSelectorState
    extends State<FullscreenEpisodeSelector> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToCurrentEpisode());
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
    final index =
        episodes.indexWhere((ep) => ep.number == widget.currentEpisode);
    if (index < 0) return;
    const crossAxisCount = 3;
    const itemHeight = 52.0;
    const mainAxisSpacing = 10.0;
    const padding = 20.0;
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
            const Text(
              '选集',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
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
        return _buildEpisodeCard(episode, isCurrent);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrent)
              Container(
                width: 18,
                height: 3,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Text(
              '${episode.number}',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? context.colors.primary
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
