import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../entities/batch_image_entity.dart';
import '../entities/camera_config_entity.dart';

abstract class CameraRepository {
  Future<void> initializeCamera();
  CameraController? get controller;
  Future<void> setZoomLevel(double zoom);
  Future<void> setFocusPoint(Offset point);
  Future<BatchImageEntity> capturePhoto(String batchId);
  Future<void> toggleFlash();
  Future<void> dispose();
  Stream<CameraConfigEntity> get configStream;
  CameraConfigEntity get currentConfig;
}
