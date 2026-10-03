import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/camera/camera_bloc.dart';
import '../blocs/camera/camera_event.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_event.dart';
import '../blocs/sync/sync_state.dart';
import '../widgets/batch_card.dart';

class UploadManagerScreen extends StatelessWidget {
  const UploadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Upload Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          BlocBuilder<SyncBloc, SyncState>(
            builder: (context, state) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: state.isOnline
                      ? AppTheme.statusSynced.withValues(alpha: 0.15)
                      : AppTheme.statusFailed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.isOnline
                        ? AppTheme.statusSynced
                        : AppTheme.statusFailed,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isOnline ? Icons.wifi : Icons.wifi_off,
                      size: 14,
                      color: state.isOnline
                          ? AppTheme.statusSynced
                          : AppTheme.statusFailed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: state.isOnline
                            ? AppTheme.statusSynced
                            : AppTheme.statusFailed,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.cardBg,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, syncState) {
          final batches = syncState.validBatches;
          final isSyncing = syncState.syncStatus == SyncEngineStatus.running;

          return Column(
            children: [
              // 1. Telemetry Queue Overview Banner & Simulation Switch
              _buildTelemetryHeader(context, syncState),

              // 2. Action Bar: Sync All & Start New Batch
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (isSyncing || syncState.pendingCount == 0)
                            ? null
                            : () {
                                context
                                    .read<SyncBloc>()
                                    .add(TriggerSyncAllEvent());
                              },
                        icon: isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.black),
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          isSyncing
                              ? 'SYNCING QUEUE...'
                              : 'SYNC ALL (${syncState.pendingCount})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<CameraBloc>().add(NewBatchEvent());
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: const Text('NEW BATCH'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.cyanAccent,
                        side: const BorderSide(color: AppTheme.cyanAccent),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppTheme.surfaceBorder, height: 1),

              // 3. Batches List or Empty State
              Expanded(
                child: batches.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        itemCount: batches.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemBuilder: (context, index) {
                          final batch = batches[index];
                          return BatchCard(
                            batch: batch,
                            onUploadPressed: () {
                              context.read<SyncBloc>().add(
                                    TriggerUploadBatchEvent(batch.id),
                                  );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTelemetryHeader(BuildContext context, SyncState syncState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          // Stat Counters Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCounter(
                'TOTAL',
                '${syncState.validBatches.length}',
                Colors.white,
              ),
              Container(width: 1, height: 32, color: AppTheme.surfaceBorder),
              _buildStatCounter(
                'PENDING',
                '${syncState.pendingCount}',
                syncState.pendingCount > 0
                    ? Colors.amberAccent
                    : Colors.white60,
              ),
              Container(width: 1, height: 32, color: AppTheme.surfaceBorder),
              _buildStatCounter(
                'SYNCED',
                '${syncState.syncedCount}',
                AppTheme.statusSynced,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.surfaceBorder, height: 1),
          const SizedBox(height: 10),

          // Network Simulation Switch (for testing resilience)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.cell_tower_rounded,
                    size: 18,
                    color: syncState.simulateNetworkFailure
                        ? AppTheme.statusFailed
                        : AppTheme.cyanAccent,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Simulate Network Outage',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        syncState.simulateNetworkFailure
                            ? 'Fails API uploads to verify queue retry'
                            : 'Uploads will succeed normally',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: syncState.simulateNetworkFailure,
                activeThumbColor: AppTheme.statusFailed,
                onChanged: (val) {
                  context.read<SyncBloc>().add(
                        ToggleNetworkFailureSimulationEvent(val),
                      );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sync Queue Empty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No photo batches in queue. Tap below or return to the camera viewfinder to capture photos into a batch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('OPEN CAMERA VIEWFINDER'),
            ),
          ],
        ),
      ),
    );
  }
}
