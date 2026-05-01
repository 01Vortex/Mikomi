import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'message_dialog.dart';

class DoubleBackExitScope extends StatefulWidget {
  const DoubleBackExitScope({
    super.key,
    required this.child,
    this.interval = const Duration(seconds: 2),
  });

  final Widget child;
  final Duration interval;

  @override
  State<DoubleBackExitScope> createState() => _DoubleBackExitScopeState();
}

class _DoubleBackExitScopeState extends State<DoubleBackExitScope> {
  DateTime? _lastBackPressedAt;

  void _handleBackPressed() {
    final now = DateTime.now();
    final canExit = _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) <= widget.interval;

    if (canExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPressedAt = now;
    MessageDialog.info(context, '再按一次返回键退出应用');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: widget.child,
    );
  }
}
