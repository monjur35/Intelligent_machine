import 'package:equatable/equatable.dart';
import 'batch_image_entity.dart';

enum BatchStatus { queued, syncing, synced, failed }

class BatchEntity extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<BatchImageEntity> images;
  final BatchStatus status;
  final int retryCount;
  final String? errorMessage;

  const BatchEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.images = const [],
    this.status = BatchStatus.queued,
    this.retryCount = 0,
    this.errorMessage,
  });

  int get totalSizeBytes =>
      images.fold(0, (sum, item) => sum + item.fileSizeBytes);

  BatchEntity copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<BatchImageEntity>? images,
    BatchStatus? status,
    int? retryCount,
    String? errorMessage,
  }) {
    return BatchEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        images,
        status,
        retryCount,
        errorMessage,
      ];
}
