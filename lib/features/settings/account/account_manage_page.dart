import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';
import 'package:mikomi/core/services/auth_service.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isLoggedIn = authService.isLoggedIn;
    final userInfo = authService.mikomiUserInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('账号管理')),
      body: ListView(
        children: [
          if (isLoggedIn && userInfo != null) ...[
            // 用户信息卡片
            _buildUserCard(context, authService, userInfo),
            const Divider(height: 1),
            // 账号信息
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('用户ID'),
              subtitle: Text('${authService.userId}'),
            ),
          ] else ...[
            // 未登录状态
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: context.colors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '未登录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '登录后可同步收藏、历史记录等数据',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('立即登录'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    AuthService authService,
    MikomiUser userInfo,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 32,
            backgroundColor: context.colors.primaryContainer,
            child: Icon(
              Icons.person,
              size: 32,
              color: context.colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userInfo.nickname,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userInfo.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
