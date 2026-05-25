import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/comment_tab_content.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/episode/episode_tab_content.dart';
import 'package:mikomi/features/video/ui/widgets/video_tab.dart';

/// 视频页面底部：弹幕/剧集 Tab + 输入栏
class VideoTabsSection extends StatelessWidget {
  final VideoPageState pageState;
  final TabController tabController;
  final TextEditingController danmakuController;
  final Future<void> Function(bool enabled) onDanmakuToggle;
  final VoidCallback onVideoSourceTap;
  final VoidCallback onDanmakuSettingsTap;
  final Future<void> Function(DanmakuConfig config) onDanmakuConfigChanged;
  final VideoPageController controller;

  const VideoTabsSection({
    super.key,
    required this.pageState,
    required this.tabController,
    required this.danmakuController,
    required this.onDanmakuToggle,
    required this.onVideoSourceTap,
    required this.onDanmakuSettingsTap,
    required this.onDanmakuConfigChanged,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final danmaku = pageState.danmaku;
    final episode = pageState.episode;
    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          VideoTab(
            tabController: tabController,
            isDanmakuEnabled: danmaku.isDanmakuEnabled,
            isDanmakuInputExpanded: danmaku.isInputExpanded,
            onDanmakuToggle: () => onDanmakuToggle(!danmaku.isDanmakuEnabled),
            onDanmakuInputTap: controller.expandDanmakuInput,
            onDanmakuSettingsTap: onDanmakuSettingsTap,
            onVideoSourceTap: onVideoSourceTap,
            currentSourceName: pageState.source.currentSourceName,
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              physics: danmaku.isDanmakuEnabled
                  ? const NeverScrollableScrollPhysics()
                  : null,
              children: [
                EpisodeTabContent(
                  isLoading: episode.isLoading,
                  episodes: episode.episodes,
                  isDescending: episode.isDescending,
                  isEpisodesExpanded: episode.isExpanded,
                  currentEpisode: episode.currentEpisodeNumber,
                  onEpisodeSelected: controller.playEpisode,
                  onToggleExpand: controller.toggleEpisodeListExpanded,
                  onToggleSort: controller.toggleEpisodeSort,
                ),
                const CommentTabContent.VideoComment(),
              ],
            ),
          ),
          if (danmaku.isInputExpanded)
            DanmakuInputBar(
              controller: danmakuController,
              onSend: () {
                if (danmakuController.text.isNotEmpty) {
                  danmakuController.clear();
                }
              },
              onClose: () {
                controller.collapseDanmakuInput();
                danmakuController.clear();
              },
            ),
        ],
      ),
    );
  }
}
