import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/shared/theme_extensions.dart';

/// 弹幕渲染层 —— 供小屏和全屏共用
/// 包裹在 [IgnorePointer] 内，不拦截触摸事件
class DanmakuLayer extends StatelessWidget {
  final Function(DanmakuController) onControllerCreated;
  final double fontSize;
  final double opacity;
  final double speed;
  final double area;
  final double strokeWidth;
  final bool hideTop;
  final bool hideBottom;
  final bool hideScroll;

  const DanmakuLayer({
    super.key,
    required this.onControllerCreated,
    this.fontSize = 16.0,
    this.opacity = 1.0,
    this.speed = 8.0,
    this.area = 0.5,
    this.strokeWidth = 1.0,
    this.hideTop = false,
    this.hideBottom = true,
    this.hideScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DanmakuScreen(
        createdController: onControllerCreated,
        option: DanmakuOption(
          fontSize: fontSize,
          opacity: opacity,
          duration: speed,
          strokeWidth: strokeWidth,
          area: area,
          hideTop: hideTop,
          hideBottom: hideBottom,
          hideScroll: hideScroll,
        ),
      ),
    );
  }
}

/// 弹幕发送输入条 —— 小屏底部 Sheet 样式
class DanmakuInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onClose;

  const DanmakuInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(color: context.colors.outlineVariant, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.send,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '点我发弹幕',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: onSend,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 全屏内联弹幕输入框（嵌在底部控制栏横向滚动里）
class DanmakuInlineInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const DanmakuInlineInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final inputWidth =
        (MediaQuery.sizeOf(context).width * 0.18).clamp(80.0, 150.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: inputWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(
              hintText: '发弹幕',
              hintStyle: TextStyle(color: Colors.white60, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onSend,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '发送',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
