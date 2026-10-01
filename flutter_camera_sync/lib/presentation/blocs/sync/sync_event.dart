import 'package:equatable/equatable.dart';
import '../../../domain/entities/batch_entity.dart';

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class LoadBatchesEvent extends SyncEvent {}

class BatchesUpdatedEvent extends SyncEvent {
  final List<BatchEntity> batches;
  const BatchesUpdatedEvent(this.batches);

  @override
  List<Object?> get props => [batches];
}

class TriggerUploadBatchEvent extends SyncEvent {
  final String batchId;
  const TriggerUploadBatchEvent(this.batchId);

  @override
  List<Object?> get props => [batchId];
}

class TriggerSyncAllEvent extends SyncEvent {}

class ConnectivityChangedEvent extends SyncEvent {
  final bool isConnected;
  const ConnectivityChangedEvent(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}

class ToggleNetworkFailureSimulationEvent extends SyncEvent {
  final bool forceFailure;
  const ToggleNetworkFailureSimulationEvent(this.forceFailure);

  @override
  List<Object?> get props => [forceFailure];
}
