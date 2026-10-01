import 'package:flutter/material.dart';
import '../entities/batch_image_entity.dart';
import '../repositories/camera_repository.dart';

class InitializeCameraUseCase {
  final CameraRepository repository;
  InitializeCameraUseCase(this.repository);

  Future<void> call() => repository.initializeCamera();
}

class UpdateZoomUseCase {
  final CameraRepository repository;
  UpdateZoomUseCase(this.repository);

  Future<void> call(double zoom) => repository.setZoomLevel(zoom);
}

class SetFocusPointUseCase {
  final CameraRepository repository;
  SetFocusPointUseCase(this.repository);

  Future<void> call(Offset point) => repository.setFocusPoint(point);
}

class CaptureBatchImageUseCase {
  final CameraRepository repository;
  CaptureBatchImageUseCase(this.repository);

  Future<BatchImageEntity> call(String batchId) =>
      repository.capturePhoto(batchId);
}
