import 'package:equatable/equatable.dart';
import '../../../domain/entities/batch_entity.dart';
import '../../../domain/entities/camera_config_entity.dart';

class CameraState extends Equatable {
  final CameraConfigEntity config;
  final BatchEntity? activeBatch;
  final bool isCapturing;
  final bool showFocusAnimation;
  final String? message;

  const CameraState({
    this.config = const CameraConfigEntity(),
    this.activeBatch,
    this.isCapturing = false,
    this.showFocusAnimation = false,
    this.message,
  });

  CameraState copyWith({
    CameraConfigEntity? config,
    BatchEntity? activeBatch,
    bool? isCapturing,
    bool? showFocusAnimation,
    String? message,
  }) {
    return CameraState(
      config: config ?? this.config,
      activeBatch: activeBatch ?? this.activeBatch,
      isCapturing: isCapturing ?? this.isCapturing,
      showFocusAnimation: showFocusAnimation ?? this.showFocusAnimation,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
        config,
        activeBatch,
        isCapturing,
        showFocusAnimation,
        message,
      ];
}
