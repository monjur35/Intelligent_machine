import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/camera_config_entity.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCameraEvent extends CameraEvent {}

class CameraConfigUpdatedEvent extends CameraEvent {
  final CameraConfigEntity config;
  const CameraConfigUpdatedEvent(this.config);

  @override
  List<Object?> get props => [config];
}

class ChangeZoomEvent extends CameraEvent {
  final double zoom;
  const ChangeZoomEvent(this.zoom);

  @override
  List<Object?> get props => [zoom];
}

class SetZoomRatioEvent extends CameraEvent {
  final double ratio;
  const SetZoomRatioEvent(this.ratio);

  @override
  List<Object?> get props => [ratio];
}

class TapFocusEvent extends CameraEvent {
  final Offset point;
  const TapFocusEvent(this.point);

  @override
  List<Object?> get props => [point];
}

class ToggleFlashEvent extends CameraEvent {}

class CapturePhotoEvent extends CameraEvent {}

class NewBatchEvent extends CameraEvent {}
