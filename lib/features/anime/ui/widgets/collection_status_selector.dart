import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';

enum CollectionStatus { notCollected, wish, watching, watched, onHold, dropped }

class CollectionStatusSelector extends StatelessWidget {
  final CollectionStatus currentStatus;
  final Function(CollectionStatus) onStatusChanged;

  const CollectionStatusSelector({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getStatusColor(currentStatus),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => _showStatusMenu(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStatusIcon(currentStatus), color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              _getStatusText(currentStatus),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...CollectionStatus.values.map((status) {
              final isSelected = status == currentStatus;
              return InkWell(
                onTap: () {
                  onStatusChanged(status);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: isSelected
                      ? _getStatusColor(status).withValues(alpha: 0.1)
                      : null,
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 16,
                          color: isSelected
                              ? _getStatusColor(status)
                              : AppColors.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          color: _getStatusColor(status),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return Icons.favorite_border;
      case CollectionStatus.wish:
        return Icons.favorite_border;
      case CollectionStatus.watching:
        return Icons.favorite;
      case CollectionStatus.watched:
        return Icons.star;
      case CollectionStatus.onHold:
        return Icons.schedule;
      case CollectionStatus.dropped:
        return Icons.heart_broken;
    }
  }

  String _getStatusText(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return '未收藏';
      case CollectionStatus.wish:
        return '未追';
      case CollectionStatus.watching:
        return '在看';
      case CollectionStatus.watched:
        return '想看';
      case CollectionStatus.onHold:
        return '搁置';
      case CollectionStatus.dropped:
        return '抛弃';
    }
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return const Color(0xFF9E9E9E);
      case CollectionStatus.wish:
        return const Color(0xFFB07C6F);
      case CollectionStatus.watching:
        return const Color(0xFF8B6F5C);
      case CollectionStatus.watched:
        return const Color(0xFF7D6B5E);
      case CollectionStatus.onHold:
        return const Color(0xFFA89080);
      case CollectionStatus.dropped:
        return const Color(0xFF9E8B7E);
    }
  }
}
