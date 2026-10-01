import '../entities/batch_entity.dart';
import '../repositories/sync_repository.dart';

class GetBatchesUseCase {
  final SyncRepository repository;
  GetBatchesUseCase(this.repository);

  Future<List<BatchEntity>> call() => repository.getAllBatches();
  Stream<List<BatchEntity>> get stream => repository.batchesStream;
}

class CreateBatchUseCase {
  final SyncRepository repository;
  CreateBatchUseCase(this.repository);

  Future<BatchEntity> call([String? name]) => repository.createNewBatch(name);
}

class QueueBatchUseCase {
  final SyncRepository repository;
  QueueBatchUseCase(this.repository);

  Future<void> call(String batchId) => repository.queueBatchForUpload(batchId);
}

class ProcessSyncQueueUseCase {
  final SyncRepository repository;
  ProcessSyncQueueUseCase(this.repository);

  Future<void> call() => repository.processSyncQueue();
}

class RetryFailedBatchesUseCase {
  final SyncRepository repository;
  RetryFailedBatchesUseCase(this.repository);

  Future<void> call() => repository.retryFailedBatches();
}
