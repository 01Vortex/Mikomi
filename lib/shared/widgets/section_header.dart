import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMoreTap;

  const SectionHeader({super.key, required this.title, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onMoreTap != null)
            GestureDetector(
              onTap: onMoreTap,
              child: Text(
                '更多',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
