import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/camera_repository.dart';
import '../../../domain/repositories/sync_repository.dart';
import 'camera_event.dart';
import 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final CameraRepository cameraRepository;
  final SyncRepository syncRepository;
  StreamSubscription? _configSub;

  CameraController? get controller => cameraRepository.controller;

  CameraBloc({required this.cameraRepository, required this.syncRepository})
    : super(const CameraState()) {
    on<InitializeCameraEvent>(_onInitialize);
    on<ChangeZoomEvent>(_onChangeZoom);
    on<SetZoomRatioEvent>(_onSetZoomRatio);
    on<TapFocusEvent>(_onTapFocus);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<CapturePhotoEvent>(_onCapturePhoto);
    on<NewBatchEvent>(_onNewBatch);
    on<CameraConfigUpdatedEvent>((event, emit) {
      emit(state.copyWith(config: event.config));
    });

    _configSub = cameraRepository.configStream.listen((config) {
      add(CameraConfigUpdatedEvent(config));
    });
  }

  bool _isInitializing = false;

  Future<void> _onInitialize(
    InitializeCameraEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await cameraRepository.initializeCamera();
      final batch = state.activeBatch ?? await syncRepository.createNewBatch();
      emit(
        state.copyWith(
          config: cameraRepository.currentConfig,
          activeBatch: batch,
        ),
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _onChangeZoom(
    ChangeZoomEvent event,
    Emitter<CameraState> emit,
  ) async {
    await cameraRepository.setZoomLevel(event.zoom);
  }

  Future<void> _onSetZoomRatio(
    SetZoomRatioEvent event,
    Emitter<CameraState> emit,
  ) async {
    await cameraRepository.setZoomLevel(event.ratio);
  }

  Future<void> _onTapFocus(
    TapFocusEvent event,
    Emitter<CameraState> emit,
  ) async {
    await cameraRepository.setFocusPoint(event.point);
    emit(state.copyWith(showFocusAnimation: true));

    // Auto-dismiss the visual focus indicator after 1.8 seconds
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!isClosed) {
      emit(state.copyWith(showFocusAnimation: false));
    }
  }

  Future<void> _onToggleFlash(
    ToggleFlashEvent event,
    Emitter<CameraState> emit,
  ) async {
    await cameraRepository.toggleFlash();
  }

  Future<void> _onCapturePhoto(
    CapturePhotoEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (state.activeBatch == null || state.isCapturing) return;

    emit(state.copyWith(isCapturing: true));
    try {
      final image = await cameraRepository.capturePhoto(state.activeBatch!.id);
      await syncRepository.addImageToBatch(state.activeBatch!.id, image);

      // Refresh active batch with newly added image
      final updatedBatch = state.activeBatch!.copyWith(
        images: [...state.activeBatch!.images, image],
      );

      emit(state.copyWith(isCapturing: false, activeBatch: updatedBatch));
    } catch (e) {
      emit(state.copyWith(isCapturing: false, message: 'Capture failed: $e'));
    }
  }

  Future<void> _onNewBatch(
    NewBatchEvent event,
    Emitter<CameraState> emit,
  ) async {
    final batch = await syncRepository.createNewBatch();
    emit(state.copyWith(activeBatch: batch));
  }

  @override
  Future<void> close() {
    _configSub?.cancel();
    return super.close();
  }
}
