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
        final newStatus = currentStatus == CollectionStatus.notCollected
            ? CollectionStatus.collected
            : CollectionStatus.notCollected;
        onStatusChanged(newStatus);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _getStatusColor(currentStatus),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(_getStatusIcon(currentStatus), color: Colors.white, size: 20),
      ),
    );
  }

  IconData _getStatusIcon(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return Icons.star_border;
      case CollectionStatus.collected:
        return Icons.star;
    }
  }

  Color _getStatusColor(CollectionStatus status) {
    switch (status) {
      case CollectionStatus.notCollected:
        return const Color(0xFF9E9E9E);
      case CollectionStatus.collected:
        return const Color(0xFFF59E0B);
    }
  }
}
