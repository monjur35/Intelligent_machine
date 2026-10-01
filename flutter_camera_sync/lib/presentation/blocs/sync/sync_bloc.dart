import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/network_info.dart';
import '../../../data/datasources/remote/mock_upload_api.dart';
import '../../../domain/repositories/sync_repository.dart';
import 'sync_event.dart';
import 'sync_state.dart';

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository syncRepository;
  final NetworkInfo networkInfo;
  final RemoteSyncApi remoteApi;

  StreamSubscription? _batchesSub;
  StreamSubscription? _connectivitySub;

  SyncBloc({
    required this.syncRepository,
    required this.networkInfo,
    required this.remoteApi,
  }) : super(const SyncState()) {
    on<LoadBatchesEvent>(_onLoadBatches);
    on<BatchesUpdatedEvent>(_onBatchesUpdated);
    on<TriggerUploadBatchEvent>(_onTriggerUploadBatch);
    on<TriggerSyncAllEvent>(_onTriggerSyncAll);
    on<ConnectivityChangedEvent>(_onConnectivityChanged);
    on<ToggleNetworkFailureSimulationEvent>(_onToggleSimulation);

    // Subscribe to database batch updates
    _batchesSub = syncRepository.batchesStream.listen((batches) {
      add(BatchesUpdatedEvent(batches));
    });

    // Subscribe to network connectivity transitions
    _connectivitySub = networkInfo.onConnectivityChanged.listen((isOnline) {
      add(ConnectivityChangedEvent(isOnline));
    });

    _init();
  }

  Future<void> _init() async {
    final online = await networkInfo.isConnected;
    add(ConnectivityChangedEvent(online));
    add(LoadBatchesEvent());
  }

  Future<void> _onLoadBatches(
    LoadBatchesEvent event,
    Emitter<SyncState> emit,
  ) async {
    final batches = await syncRepository.getAllBatches();
    emit(state.copyWith(batches: batches));
  }

  void _onBatchesUpdated(
    BatchesUpdatedEvent event,
    Emitter<SyncState> emit,
  ) {
    emit(state.copyWith(batches: event.batches));
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChangedEvent event,
    Emitter<SyncState> emit,
  ) async {
    final wasOffline = !state.isOnline;
    emit(state.copyWith(
      isOnline: event.isConnected,
      syncStatus: event.isConnected
          ? SyncEngineStatus.idle
          : SyncEngineStatus.offline,
    ));

    // Assessment Requirement: Automatically retry upload once stable connection is detected without user intervention
    if (wasOffline && event.isConnected) {
      add(TriggerSyncAllEvent());
    }
  }

  Future<void> _onTriggerUploadBatch(
    TriggerUploadBatchEvent event,
    Emitter<SyncState> emit,
  ) async {
    emit(state.copyWith(syncStatus: SyncEngineStatus.running));
    await syncRepository.queueBatchForUpload(event.batchId);
    emit(state.copyWith(syncStatus: SyncEngineStatus.idle));
  }

  Future<void> _onTriggerSyncAll(
    TriggerSyncAllEvent event,
    Emitter<SyncState> emit,
  ) async {
    if (!state.isOnline) {
      emit(state.copyWith(
        message: 'Cannot sync while offline. Batches remain safe in local queue.',
      ));
      return;
    }

    emit(state.copyWith(syncStatus: SyncEngineStatus.running));
    await syncRepository.processSyncQueue();
    emit(state.copyWith(syncStatus: SyncEngineStatus.idle));
  }

  void _onToggleSimulation(
    ToggleNetworkFailureSimulationEvent event,
    Emitter<SyncState> emit,
  ) {
    remoteApi.setForceFailure(event.forceFailure);
    emit(state.copyWith(
      simulateNetworkFailure: event.forceFailure,
      message: event.forceFailure
          ? 'Network failure simulated: API will fail and batches stay queued.'
          : 'Network restored: auto-retry enabled.',
    ));

    if (!event.forceFailure && state.isOnline) {
      // Auto retry immediately when simulated network is restored
      add(TriggerSyncAllEvent());
    }
  }

  @override
  Future<void> close() {
    _batchesSub?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
