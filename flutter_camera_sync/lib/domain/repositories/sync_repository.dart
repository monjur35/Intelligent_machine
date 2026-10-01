import '../entities/batch_entity.dart';
import '../entities/batch_image_entity.dart';

abstract class SyncRepository {
  Future<List<BatchEntity>> getAllBatches();
  Future<BatchEntity> createNewBatch([String? name]);
  Future<void> addImageToBatch(String batchId, BatchImageEntity image);
  Future<void> queueBatchForUpload(String batchId);
  Future<bool> uploadBatch(BatchEntity batch);
  Future<void> processSyncQueue();
  Future<void> retryFailedBatches();
  Stream<List<BatchEntity>> get batchesStream;
}
