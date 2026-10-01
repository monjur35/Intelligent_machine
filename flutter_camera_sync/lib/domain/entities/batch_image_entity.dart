import 'package:equatable/equatable.dart';

class BatchImageEntity extends Equatable {
  final String id;
  final String batchId;
  final String filePath;
  final String? thumbnailPath;
  final int fileSizeBytes;
  final DateTime capturedAt;
  final bool isUploaded;

  const BatchImageEntity({
    required this.id,
    required this.batchId,
    required this.filePath,
    this.thumbnailPath,
    required this.fileSizeBytes,
    required this.capturedAt,
    this.isUploaded = false,
  });

  BatchImageEntity copyWith({
    String? id,
    String? batchId,
    String? filePath,
    String? thumbnailPath,
    int? fileSizeBytes,
    DateTime? capturedAt,
    bool? isUploaded,
  }) {
    return BatchImageEntity(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        batchId,
        filePath,
        thumbnailPath,
        fileSizeBytes,
        capturedAt,
        isUploaded,
      ];
}
