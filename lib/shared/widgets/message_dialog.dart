import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    // 移除之前的消息
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // error和warning需要手动关闭，不自动消失
    final shouldAutoDismiss =
        type != MessageType.error && type != MessageType.warning;
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
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // 只有设置了duration才自动消失
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
        return const Color(0xFF0CD373);
      case MessageType.error:
        return const Color(0xFFFF8B8B);
      case MessageType.warning:
        return const Color(0xFFFDFF9A);
      case MessageType.info:
        return const Color(0xFF97D2FF);
    }
  }

  Color _getTextColor() {
    // 黄色背景使用深色文字
    if (widget.type == MessageType.warning) {
      return Colors.black87;
    }
    return Colors.white;
  }

  Color _getIconBackgroundColor() {
    // 黄色背景使用深色图标背景
    if (widget.type == MessageType.warning) {
      return Colors.black.withValues(alpha: 0.1);
    }
    return Colors.white.withValues(alpha: 0.2);
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
    final isErrorOrWarning =
        widget.type == MessageType.error || widget.type == MessageType.warning;
    final textColor = _getTextColor();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: isErrorOrWarning ? null : _dismiss,
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
                        color: _getBackgroundColor().withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getBackgroundColor().withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getIconBackgroundColor(),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIcon(), color: textColor, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  widget.message,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                                if (isErrorOrWarning) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: widget.message),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text('已复制到剪贴板'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy,
                                          size: 14,
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '复制',
                                          style: TextStyle(
                                            color: textColor.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _getIconBackgroundColor(),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: textColor,
                                size: 18,
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
        ),
      ),
    );
  }
}
