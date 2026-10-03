import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/batch_entity.dart';
import 'status_pill.dart';

class BatchCard extends StatelessWidget {
  final BatchEntity batch;
  final VoidCallback onUploadPressed;

  const BatchCard({
    super.key,
    required this.batch,
    required this.onUploadPressed,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '${dt.month}/${dt.day} $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final isSyncing = batch.status == BatchStatus.syncing;
    final isSynced = batch.status == BatchStatus.synced;
    final isFailed = batch.status == BatchStatus.failed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSyncing
              ? AppTheme.cyanAccent.withValues(alpha: 0.5)
              : isFailed
                  ? AppTheme.statusFailed.withValues(alpha: 0.4)
                  : AppTheme.surfaceBorder,
          width: isSyncing ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isSyncing)
            BoxShadow(
              color: AppTheme.cyanAccent.withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Batch Name / ID & Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cyanAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: AppTheme.cyanAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Created: ${_formatTimestamp(batch.createdAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(status: batch.status),
              ],
            ),
            const SizedBox(height: 14),

            // Telemetry Metadata Row: Images count, size, retry attempts
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetaItem(
                    icon: Icons.photo_library_outlined,
                    label: 'Images',
                    value: '${batch.images.length}',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _buildMetaItem(
                    icon: Icons.data_usage_rounded,
                    label: 'Size',
                    value: _formatFileSize(batch.totalSizeBytes),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _buildMetaItem(
                    icon: Icons.replay_rounded,
                    label: 'Retries',
                    value: '${batch.retryCount}/3',
                    valueColor: batch.retryCount > 0 ? Colors.amberAccent : null,
                  ),
                ],
              ),
            ),

            // Optional Image Thumbnails Row (if images exist)
            if (batch.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: batch.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final img = batch.images[index];
                    final file = File(img.filePath);
                    final exists = file.existsSync();

                    return Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: exists
                          ? Image.file(
                              file,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image,
                                size: 20,
                                color: Colors.white38,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 20,
                              color: Colors.white38,
                            ),
                    );
                  },
                ),
              ),
            ],

            // Error notice banner if failed
            if (isFailed && batch.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.statusFailed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.statusFailed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppTheme.statusFailed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        batch.errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.statusFailed,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Bottom Actions / Status Row
            if (isSyncing) ...[
              Row(
                children: const [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.cyanAccent),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Syncing batch payload to server...',
                    style: TextStyle(
                      color: AppTheme.cyanGlow,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (isSynced) ...[
              Row(
                children: const [
                  Icon(
                    Icons.cloud_done_rounded,
                    size: 18,
                    color: AppTheme.statusSynced,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Synced to remote cloud repository',
                    style: TextStyle(
                      color: AppTheme.statusSynced,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: batch.images.isEmpty ? null : onUploadPressed,
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: Text(
                    isFailed ? 'RETRY BATCH UPLOAD' : 'UPLOAD BATCH',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.cyanAccent,
                    side: const BorderSide(color: AppTheme.cyanAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
