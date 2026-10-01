import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/batch_image_entity.dart';
import '../../domain/entities/camera_config_entity.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/camera/camera_data_source.dart';

class CameraRepositoryImpl implements CameraRepository {
  final CameraDataSource dataSource;

  CameraRepositoryImpl({CameraDataSource? dataSource})
      : dataSource = dataSource ?? CameraDataSourceImpl();

  @override
  Future<void> initializeCamera() => dataSource.initialize();

  @override
  CameraController? get controller => dataSource.controller;

  @override
  Future<void> setZoomLevel(double zoom) => dataSource.setZoom(zoom);

  @override
  Future<void> setFocusPoint(Offset point) => dataSource.setFocus(point);

  @override
  Future<BatchImageEntity> capturePhoto(String batchId) =>
      dataSource.capturePhoto(batchId);

  @override
  Future<void> toggleFlash() => dataSource.toggleFlash();

  @override
  Future<void> dispose() => dataSource.dispose();

  @override
  Stream<CameraConfigEntity> get configStream => dataSource.configStream;

  @override
  CameraConfigEntity get currentConfig => dataSource.currentConfig;
}
