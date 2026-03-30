import 'package:flutter/material.dart';

enum VideoFitMode {
  contain, // 自动（保持比例完整显示）
  cover,   // 剪裁填充
  fill,    // 拉伸填充
}

extension VideoFitModeExt on VideoFitMode {
  BoxFit get boxFit {
    switch (this) {
      case VideoFitMode.contain:
        return BoxFit.contain;
      case VideoFitMode.cover:
        return BoxFit.cover;
      case VideoFitMode.fill:
        return BoxFit.fill;
    }
  }

  IconData get icon {
    switch (this) {
      case VideoFitMode.contain:
        return Icons.fit_screen_outlined;
      case VideoFitMode.cover:
        return Icons.crop_outlined;
      case VideoFitMode.fill:
        return Icons.fullscreen_outlined;
    }
  }

  String get label {
    switch (this) {
      case VideoFitMode.contain:
        return '自动';
      case VideoFitMode.cover:
        return '剪裁填充';
      case VideoFitMode.fill:
        return '拉伸填充';
    }
  }
}

/// 视频填充模式按钮，点击弹出选项菜单
class VideoFitButton extends StatelessWidget {
  final VideoFitMode fitMode;
  final ValueChanged<VideoFitMode> onChanged;

  const VideoFitButton({
    super.key,
    required this.fitMode,
    required this.onChanged,
  });

  void _showMenu(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;

    showMenu<VideoFitMode>(
      context: context,
      position: RelativeRect.fromLTRB(
        pos.dx,
        pos.dy - 148,
        pos.dx + size.width,
        pos.dy,
      ),
      color: Colors.black.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 120),
      items: VideoFitMode.values.map((mode) {
        final selected = mode == fitMode;
        return PopupMenuItem<VideoFitMode>(
          value: mode,
          height: 44,
          padding: EdgeInsets.zero,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              mode.label,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((mode) {
      if (mode != null) onChanged(mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          fitMode.icon,
          color: fitMode == VideoFitMode.contain
              ? Colors.white
              : Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}
