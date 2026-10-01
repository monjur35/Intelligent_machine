import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/batch_entity.dart';

class StatusPill extends StatelessWidget {
  final BatchStatus status;
  final bool isCompact;

  const StatusPill({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      BatchStatus.queued => (
          AppTheme.statusQueued,
          'QUEUED',
          Icons.schedule_rounded,
        ),
      BatchStatus.syncing => (
          AppTheme.statusSyncing,
          'SYNCING',
          Icons.sync_rounded,
        ),
      BatchStatus.synced => (
          AppTheme.statusSynced,
          'SYNCED',
          Icons.check_circle_rounded,
        ),
      BatchStatus.failed => (
          AppTheme.statusFailed,
          'FAILED',
          Icons.error_outline_rounded,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isCompact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
