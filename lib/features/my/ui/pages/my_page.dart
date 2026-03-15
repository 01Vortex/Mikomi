import 'package:flutter/material.dart';
import 'package:mikomi/features/my/ui/widgets/profile_header.dart';
import 'package:mikomi/features/my/ui/widgets/action_chips.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const ProfileHeader(nickname: '昵称', bio: '个人简介'),
                  const SizedBox(height: 24),
                  ActionChips(
                    chips: [
                      MyActionItem(label: '最近再看', onTap: () {}),
                      MyActionItem(label: '收藏', onTap: () {}),
                      MyActionItem(label: '我的下载', onTap: () {}),
                      MyActionItem(label: '我的评论', onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.palette_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  foregroundColor: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
