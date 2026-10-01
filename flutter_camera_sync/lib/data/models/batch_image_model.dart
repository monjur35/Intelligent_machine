import '../../domain/entities/batch_image_entity.dart';

class BatchImageModel extends BatchImageEntity {
  const BatchImageModel({
    required super.id,
    required super.batchId,
    required super.filePath,
    super.thumbnailPath,
    required super.fileSizeBytes,
    required super.capturedAt,
    super.isUploaded,
  });

  factory BatchImageModel.fromEntity(BatchImageEntity entity) {
    return BatchImageModel(
      id: entity.id,
      batchId: entity.batchId,
      filePath: entity.filePath,
      thumbnailPath: entity.thumbnailPath,
      fileSizeBytes: entity.fileSizeBytes,
      capturedAt: entity.capturedAt,
      isUploaded: entity.isUploaded,
    );
  }

  factory BatchImageModel.fromMap(Map<String, dynamic> map) {
    return BatchImageModel(
      id: map['id'] as String,
      batchId: map['batch_id'] as String,
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      isUploaded: (map['is_uploaded'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'file_size_bytes': fileSizeBytes,
      'captured_at': capturedAt.toIso8601String(),
      'is_uploaded': isUploaded ? 1 : 0,
    };
  }
}
