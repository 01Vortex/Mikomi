import 'package:flutter/material.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class LoginReminder extends StatelessWidget {
  const LoginReminder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.surfaceContainerHighest,
            context.colors.surfaceContainerHighest.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              '登录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '登录后同步数据',
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
