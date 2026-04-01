import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mikomi/shared/theme_extensions.dart';

class VideoTab extends StatelessWidget {
  final TabController tabController;
  final bool isDanmakuEnabled;
  final bool isDanmakuInputExpanded;
  final VoidCallback onDanmakuToggle;
  final VoidCallback onDanmakuInputTap;
  final VoidCallback onVideoSourceTap;
  final String? currentPluginName;

  const VideoTab({
    super.key,
    required this.tabController,
    required this.isDanmakuEnabled,
    required this.isDanmakuInputExpanded,
    required this.onDanmakuToggle,
    required this.onDanmakuInputTap,
    required this.onVideoSourceTap,
    required this.currentPluginName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colors.outlineVariant, width: 0.5),
        ),
      ),
      child: Stack(
        children: [
          // 底层：Tab标签，占据左侧120宽度
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 120,
            child: _buildTabSection(context),
          ),
          // 上层：右侧按钮区域，从120开始到右边
          Positioned(
            left: 120,
            right: 0,
            top: 0,
            bottom: 0,
            child: _buildActionSection(context),
          ),
        ],
      ),
    );
  }

  // Tab标签区域
  Widget _buildTabSection(BuildContext context) {
    return SizedBox(
      width: 120,
      child: TabBar(
        controller: tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.zero,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '选集'),
          Tab(text: '评论'),
        ],
      ),
    );
  }

  // 右侧按钮区域
  Widget _buildActionSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 弹幕输入提示（仅在开启弹幕时显示）
        if (isDanmakuEnabled) _buildDanmakuInputHint(context),
        // 弹幕开关按钮
        _buildDanmakuToggleButton(context),
        const SizedBox(width: 8),
        // 视频源按钮
        _buildVideoSourceButton(context),
        const SizedBox(width: 12),
      ],
    );
  }

  // 弹幕输入提示
  Widget _buildDanmakuInputHint(BuildContext context) {
    return GestureDetector(
      onTap: onDanmakuInputTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomLeft: Radius.circular(18),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          isDanmakuInputExpanded ? '弹幕输入中' : '点我发弹幕',
          style: TextStyle(
            fontSize: 14,
            color: isDanmakuInputExpanded
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  // 弹幕开关按钮
  Widget _buildDanmakuToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: onDanmakuToggle,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(isDanmakuEnabled ? 0 : 18)
              .copyWith(
                topRight: const Radius.circular(18),
                bottomRight: const Radius.circular(18),
              ),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          isDanmakuEnabled
              ? 'assets/icons/danmaku_on.svg'
              : 'assets/icons/danmaku_off.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            isDanmakuEnabled
                ? (isDanmakuInputExpanded
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // 视频源按钮
  Widget _buildVideoSourceButton(BuildContext context) {
    return GestureDetector(
      onTap: onVideoSourceTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          currentPluginName ?? '视频源',
          style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}
