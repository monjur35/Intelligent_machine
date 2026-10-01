import '../../domain/entities/batch_entity.dart';
import 'batch_image_model.dart';

class BatchModel extends BatchEntity {
  const BatchModel({
    required super.id,
    required super.name,
    required super.createdAt,
    super.images,
    super.status,
    super.retryCount,
    super.errorMessage,
  });

  factory BatchModel.fromEntity(BatchEntity entity) {
    return BatchModel(
      id: entity.id,
      name: entity.name,
      createdAt: entity.createdAt,
      images: entity.images,
      status: entity.status,
      retryCount: entity.retryCount,
      errorMessage: entity.errorMessage,
    );
  }

  factory BatchModel.fromMap(
    Map<String, dynamic> map, [
    List<BatchImageModel> images = const [],
  ]) {
    return BatchModel(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      images: images,
      status: _statusFromString(map['status'] as String?),
      retryCount: map['retry_count'] as int? ?? 0,
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  static BatchStatus _statusFromString(String? val) {
    switch (val) {
      case 'syncing':
        return BatchStatus.syncing;
      case 'synced':
        return BatchStatus.synced;
      case 'failed':
        return BatchStatus.failed;
      case 'queued':
      default:
        return BatchStatus.queued;
    }
  }
}
