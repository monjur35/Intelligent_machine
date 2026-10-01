import 'package:equatable/equatable.dart';
import '../../../domain/entities/batch_entity.dart';

enum SyncEngineStatus { idle, running, retrying, offline }

class SyncState extends Equatable {
  final List<BatchEntity> batches;
  final bool isOnline;
  final SyncEngineStatus syncStatus;
  final bool simulateNetworkFailure;
  final String? message;

  const SyncState({
    this.batches = const [],
    this.isOnline = true,
    this.syncStatus = SyncEngineStatus.idle,
    this.simulateNetworkFailure = false,
    this.message,
  });

  int get pendingCount => batches
      .where((b) =>
          b.status == BatchStatus.queued || b.status == BatchStatus.failed)
      .length;

  int get syncedCount =>
      batches.where((b) => b.status == BatchStatus.synced).length;

  SyncState copyWith({
    List<BatchEntity>? batches,
    bool? isOnline,
    SyncEngineStatus? syncStatus,
    bool? simulateNetworkFailure,
    String? message,
  }) {
    return SyncState(
      batches: batches ?? this.batches,
      isOnline: isOnline ?? this.isOnline,
      syncStatus: syncStatus ?? this.syncStatus,
      simulateNetworkFailure:
          simulateNetworkFailure ?? this.simulateNetworkFailure,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        batches,
        isOnline,
        syncStatus,
        simulateNetworkFailure,
        message,
      ];
}
