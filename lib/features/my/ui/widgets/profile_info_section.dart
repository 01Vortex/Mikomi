import 'package:flutter/material.dart';
import 'package:mikomi/shared/utils/theme_extensions.dart';

class ProfileInfoSection extends StatelessWidget {
  final String nickname;
  final String uid;
  final String bio;
  final String gender;

  const ProfileInfoSection({
    super.key,
    required this.nickname,
    required this.uid,
    required this.bio,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 头像和昵称UID横向布局
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 头像
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 4),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: context.colors.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 昵称和UID
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    uid,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 个人简介
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              bio,
              style: TextStyle(fontSize: 14, color: context.colors.onSurface),
            ),
          ),
          const SizedBox(height: 8),
          // 性别标签
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                gender,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
