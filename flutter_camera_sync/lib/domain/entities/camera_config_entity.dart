import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CameraConfigEntity extends Equatable {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> availableRatios;
  final Offset? focusPoint;
  final bool isFlashEnabled;
  final bool isReady;
  final bool isSimulated;
  final int backCameraCount;
  final int activeBackCameraIndex;

  const CameraConfigEntity({
    this.currentZoom = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 4.0,
    this.availableRatios = const [0.5, 1.0, 2.0],
    this.focusPoint,
    this.isFlashEnabled = false,
    this.isReady = false,
    this.isSimulated = false,
    this.backCameraCount = 1,
    this.activeBackCameraIndex = 0,
  });

  CameraConfigEntity copyWith({
    double? currentZoom,
    double? minZoom,
    double? maxZoom,
    List<double>? availableRatios,
    Offset? focusPoint,
    bool? isFlashEnabled,
    bool? isReady,
    bool? isSimulated,
    int? backCameraCount,
    int? activeBackCameraIndex,
  }) {
    return CameraConfigEntity(
      currentZoom: currentZoom ?? this.currentZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      availableRatios: availableRatios ?? this.availableRatios,
      focusPoint: focusPoint ?? this.focusPoint,
      isFlashEnabled: isFlashEnabled ?? this.isFlashEnabled,
      isReady: isReady ?? this.isReady,
      isSimulated: isSimulated ?? this.isSimulated,
      backCameraCount: backCameraCount ?? this.backCameraCount,
      activeBackCameraIndex: activeBackCameraIndex ?? this.activeBackCameraIndex,
    );
  }

  @override
  List<Object?> get props => [
        currentZoom,
        minZoom,
        maxZoom,
        availableRatios,
        focusPoint,
        isFlashEnabled,
        isReady,
        isSimulated,
        backCameraCount,
        activeBackCameraIndex,
      ];
}
