import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mikomi/shared/theme_extensions.dart';

class VideoTab extends StatelessWidget {
  final TabController tabController;
  final bool isDanmakuEnabled;
  final bool isDanmakuInputExpanded;
  final VoidCallback onDanmakuToggle;
  final VoidCallback onDanmakuInputTap;
  final VoidCallback onDanmakuSettingsTap;
  final VoidCallback onVideoSourceTap;
  final String? currentSourceName;

  const VideoTab({
    super.key,
    required this.tabController,
    required this.isDanmakuEnabled,
    required this.isDanmakuInputExpanded,
    required this.onDanmakuToggle,
    required this.onDanmakuInputTap,
    required this.onDanmakuSettingsTap,
    required this.onVideoSourceTap,
    required this.currentSourceName,
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
      child: Row(
        children: [
          SizedBox(width: 120, child: _buildTabSection(context)),
          Expanded(child: _buildActionSection(context)),
        ],
      ),
    );
  }

  Widget _buildTabSection(BuildContext context) {
    return TabBar(
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
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isDanmakuEnabled) _buildDanmakuInputHint(context),
        _buildDanmakuToggleButton(context),
        const SizedBox(width: 8),
        _buildDanmakuSettingsButton(context),
        const SizedBox(width: 8),
        _buildVideoSourceButton(context),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildDanmakuInputHint(BuildContext context) {
    return GestureDetector(
      onTap: onDanmakuInputTap,
      behavior: HitTestBehavior.opaque,
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

  Widget _buildDanmakuToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: onDanmakuToggle,
      behavior: HitTestBehavior.opaque,
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

  Widget _buildDanmakuSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: onDanmakuSettingsTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/icons/danmaku_setting.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            context.colors.textSecondary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSourceButton(BuildContext context) {
    return GestureDetector(
      onTap: onVideoSourceTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: Text(
          currentSourceName ?? '视频源',
          style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}
