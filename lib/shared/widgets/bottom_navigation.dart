import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                index: 0,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                index: 1,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                index: 2,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                index: 3,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isActive = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Icon(
          isActive ? activeIcon : icon,
          size: 28,
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}
