import 'package:flutter/material.dart';

enum CollectionStatus { notCollected, collected }

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
    return InkWell(
      onTap: () {
        // 直接切换状态，不显示菜单
        final newStatus = currentStatus == CollectionStatus.notCollected
            ? CollectionStatus.collected
            : CollectionStatus.notCollected;
        onStatusChanged(newStatus);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _getStatusColor(currentStatus),
          borderRadius: BorderRadius.circular(24),
        ),
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

  IconData _getStatusIcon(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return Icons.favorite_border;
      case CollectionStatus.collected:
        return Icons.favorite;
    }
  }

  String _getStatusText(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return '未收藏';
      case CollectionStatus.collected:
        return '已收藏';
    }
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return const Color(0xFF9E9E9E);
      case CollectionStatus.collected:
        return const Color(0xFFE91E63);
    }
  }
}
