import 'package:flutter/material.dart';
import 'dart:ui';

enum MessageType { success, error, warning, info }

class MessageDialog {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    required MessageType type,
    Duration? duration,
    VoidCallback? onDismiss,
  }) {
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // 只有error需要手动关闭，其他类型自动消失
    final shouldAutoDismiss = type != MessageType.error;
    final effectiveDuration =
        duration ?? (shouldAutoDismiss ? const Duration(seconds: 3) : null);

    overlayEntry = OverlayEntry(
      builder: (context) => _MessageDialogWidget(
        message: message,
        type: type,
        onDismiss: () {
          overlayEntry.remove();
          _currentOverlay = null;
          onDismiss?.call();
        },
        duration: effectiveDuration,
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void success(BuildContext context, String message) {
    show(context, message: message, type: MessageType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: MessageType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: MessageType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: MessageType.info);
  }

  static void dismiss() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}

class _MessageDialogWidget extends StatefulWidget {
  final String message;
  final MessageType type;
  final VoidCallback onDismiss;
  final Duration? duration;

  const _MessageDialogWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.duration,
  });

  @override
  State<_MessageDialogWidget> createState() => _MessageDialogWidgetState();
}

class _MessageDialogWidgetState extends State<_MessageDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    if (widget.duration != null) {
      Future.delayed(widget.duration!, () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF00FF00).withValues(alpha: 0.15); // 浅绿色
      case MessageType.error:
        return const Color(0xFFFF0000).withValues(alpha: 0.15); // 浅红色
      case MessageType.warning:
        return const Color(0xFFFFFF00).withValues(alpha: 0.15); // 浅黄色
      case MessageType.info:
        return const Color(0xFF00BFFF).withValues(alpha: 0.15); // 浅蓝色
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF00AA00); // 深绿色文字
      case MessageType.error:
        return const Color(0xFFCC0000); // 深红色文字
      case MessageType.warning:
        return const Color(0xFFCC9900); // 深黄色文字
      case MessageType.info:
        return const Color(0xFF0088CC); // 深蓝色文字
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.type) {
      case MessageType.success:
        return const Color(0xFF00AA00).withValues(alpha: 0.15);
      case MessageType.error:
        return const Color(0xFFCC0000).withValues(alpha: 0.15);
      case MessageType.warning:
        return const Color(0xFFCC9900).withValues(alpha: 0.15);
      case MessageType.info:
        return const Color(0xFF0088CC).withValues(alpha: 0.15);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case MessageType.success:
        return Icons.check_circle_rounded;
      case MessageType.error:
        return Icons.error_rounded;
      case MessageType.warning:
        return Icons.warning_rounded;
      case MessageType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _getBackgroundColor(),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(), color: textColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _getIconBackgroundColor(),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: textColor,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
