import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/batch_entity.dart';
import '../../domain/entities/batch_image_entity.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/database_helper.dart';
import '../datasources/remote/mock_upload_api.dart';
import '../models/batch_image_model.dart';
import '../models/batch_model.dart';

class SyncRepositoryImpl implements SyncRepository {
  final DatabaseHelper dbHelper;
  final RemoteSyncApi remoteApi;
  final NetworkInfo networkInfo;
  final Future<void> Function()? onSyncNeeded;

  final _batchesStreamController =
      StreamController<List<BatchEntity>>.broadcast();

  SyncRepositoryImpl({
    DatabaseHelper? dbHelper,
    RemoteSyncApi? remoteApi,
    NetworkInfo? networkInfo,
    this.onSyncNeeded,
  })  : dbHelper = dbHelper ?? DatabaseHelper.instance,
        remoteApi = remoteApi ?? MockUploadApiClient(),
        networkInfo = networkInfo ?? NetworkInfoImpl() {
    _refreshBatches();
  }

  BatchEntity? _pendingBatch;

  @override
  Stream<List<BatchEntity>> get batchesStream =>
      _batchesStreamController.stream;

  Future<void> _refreshBatches() async {
    await dbHelper.deleteEmptyBatches();
    final batches = await dbHelper.getBatches(onlyWithImages: true);
    if (!_batchesStreamController.isClosed) {
      _batchesStreamController.add(batches);
    }
  }

  @override
  Future<List<BatchEntity>> getAllBatches() async {
    await dbHelper.deleteEmptyBatches();
    return await dbHelper.getBatches(onlyWithImages: true);
  }

  @override
  Future<BatchEntity> createNewBatch([String? name]) async {
    final id = const Uuid().v4();
    final batchName = name ??
        'BATCH_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.raw';

    final batch = BatchModel(
      id: id,
      name: batchName,
      createdAt: DateTime.now(),
      status: BatchStatus.queued,
      retryCount: 0,
    );

    // Keep batch metadata in-memory until a photo is actually captured.
    // If no photo is captured, no batch is created in the database.
    _pendingBatch = batch;
    return batch;
  }

  @override
  Future<void> addImageToBatch(String batchId, BatchImageEntity image) async {
    // Ensure the batch header exists in SQLite before adding the photo (foreign key constraint)
    final existingBatch = await dbHelper.getBatch(batchId);
    if (existingBatch == null) {
      final batchToInsert = (_pendingBatch != null && _pendingBatch!.id == batchId)
          ? BatchModel.fromEntity(_pendingBatch!)
          : BatchModel(
              id: batchId,
              name:
                  'BATCH_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.raw',
              createdAt: DateTime.now(),
              status: BatchStatus.queued,
              retryCount: 0,
            );
      await dbHelper.insertBatch(batchToInsert);
    }

    final imageModel = BatchImageModel.fromEntity(image);
    await dbHelper.insertImage(imageModel);
    await _refreshBatches();
    onSyncNeeded?.call();
  }

  @override
  Future<void> queueBatchForUpload(String batchId) async {
    final batch = await dbHelper.getBatch(batchId);
    if (batch != null && batch.images.isNotEmpty) {
      final updated = batch.copyWith(status: BatchStatus.queued);
      await dbHelper.updateBatch(BatchModel.fromEntity(updated));
      await _refreshBatches();
      await processSyncQueue();
    }
  }

  @override
  Future<bool> uploadBatch(BatchEntity batch) async {
    if (batch.images.isEmpty) {
      return false;
    }
    final isOnline = await networkInfo.isConnected;
    if (!isOnline) {
      // Must remain in local queue when offline per assessment specification
      final updated = batch.copyWith(
        status: BatchStatus.queued,
        errorMessage: 'Offline: upload paused in local queue.',
      );
      await dbHelper.updateBatch(BatchModel.fromEntity(updated));
      await _refreshBatches();
      onSyncNeeded?.call();
      return false;
    }

    // Set to syncing state
    final syncingBatch = batch.copyWith(
      status: BatchStatus.syncing,
      errorMessage: null,
    );
    await dbHelper.updateBatch(BatchModel.fromEntity(syncingBatch));
    await _refreshBatches();

    try {
      final success = await remoteApi.uploadBatch(BatchModel.fromEntity(batch));
      if (success) {
        final syncedBatch = batch.copyWith(
          status: BatchStatus.synced,
          errorMessage: null,
        );
        await dbHelper.updateBatch(BatchModel.fromEntity(syncedBatch));
        await _refreshBatches();
        return true;
      }
    } catch (e) {
      // Retain in local queue and mark for resilient auto-retry
      final failedBatch = batch.copyWith(
        status: BatchStatus.failed,
        retryCount: batch.retryCount + 1,
        errorMessage: e.toString(),
      );
      await dbHelper.updateBatch(BatchModel.fromEntity(failedBatch));
      await _refreshBatches();
      onSyncNeeded?.call();
    }
    return false;
  }

  @override
  Future<void> processSyncQueue() async {
    final batches = await getAllBatches();
    final pending = batches.where((b) =>
        (b.status == BatchStatus.queued || b.status == BatchStatus.failed) &&
        b.images.isNotEmpty);

    for (final batch in pending) {
      final success = await uploadBatch(batch);
      if (!success) {
        // If an upload fails due to network, keep subsequent batches in queue
        break;
      }
    }
  }

  @override
  Future<void> retryFailedBatches() async {
    final batches = await getAllBatches();
    final failed = batches.where((b) => b.status == BatchStatus.failed && b.images.isNotEmpty);

    for (final batch in failed) {
      final queued = batch.copyWith(status: BatchStatus.queued);
      await dbHelper.updateBatch(BatchModel.fromEntity(queued));
    }
    await _refreshBatches();
    await processSyncQueue();
  }
}
