import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/camera_config_entity.dart';
import '../blocs/camera/camera_bloc.dart';
import '../blocs/camera/camera_event.dart';
import '../blocs/camera/camera_state.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';
import '../widgets/focus_indicator.dart';
import '../widgets/zoom_control_bar.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen>
    with WidgetsBindingObserver {
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  Offset? _tapFocusOffset;
  bool _hasCameraPermission = true;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkCameraPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkCameraPermission();
    }
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    final isGranted = status.isGranted;

    if (!mounted) return;

    setState(() {
      _hasCameraPermission = isGranted;
    });

    if (isGranted) {
      if (_isDialogOpen && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        _isDialogOpen = false;
      }
      context.read<CameraBloc>().add(InitializeCameraEvent());
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    if (_isDialogOpen || !mounted) return;
    _isDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.cyanAccent.withValues(alpha: 0.3)),
          ),
          title: const Row(
            children: [
              Icon(Icons.videocam_off_rounded, color: Colors.amberAccent, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Camera Permission Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Camera access is required to capture employee attendance photos. All camera actions are disabled until permission is granted.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _isDialogOpen = false;
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'Give Permission',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final status = await Permission.camera.request();
                if (status.isGranted) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    _isDialogOpen = false;
                  }
                  if (mounted) {
                    setState(() {
                      _hasCameraPermission = true;
                    });
                    context.read<CameraBloc>().add(InitializeCameraEvent());
                  }
                } else if (status.isPermanentlyDenied) {
                  await openAppSettings();
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (!_hasCameraPermission) return;
    _baseScale = _currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, CameraConfigEntity config) {
    if (!_hasCameraPermission || details.scale == 1.0) return;
    final newZoom = (_baseScale * details.scale).clamp(config.minZoom, config.maxZoom);
    setState(() {
      _currentScale = newZoom;
    });
    context.read<CameraBloc>().add(ChangeZoomEvent(newZoom));
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (!_hasCameraPermission) return;
    final local = details.localPosition;
    setState(() {
      _tapFocusOffset = local;
    });

    // Normalize coordinates for camera sensor (0.0 to 1.0)
    final normalized = Offset(
      (local.dx / constraints.maxWidth).clamp(0.0, 1.0),
      (local.dy / constraints.maxHeight).clamp(0.0, 1.0),
    );

    HapticFeedback.selectionClick();
    context.read<CameraBloc>().add(TapFocusEvent(normalized));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppTheme.cardBg,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, cameraState) {
          final config = cameraState.config;
          final controller = context.read<CameraBloc>().controller;
          final isReady = config.isReady;
          final isSimulated = config.isSimulated;

          return SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Camera Viewfinder (Hardware Camera, Simulated Viewfinder, or Permission Denied UI)
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (!_hasCameraPermission) {
                      return _buildPermissionDeniedViewfinder();
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onScaleStart: _onScaleStart,
                      onScaleUpdate: (d) => _onScaleUpdate(d, config),
                      onTapDown: (d) => _onTapDown(d, constraints),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!isReady)
                            _buildLoadingViewfinder()
                          else if (!isSimulated &&
                              controller != null &&
                              controller.value.isInitialized)
                            _buildHardwarePreview(controller)
                          else
                            _buildSimulatedViewfinder(config),

                          // Rule-of-thirds grid overlay
                          _buildGridOverlay(),

                          // Tap to Focus Reticle Animation
                          if (cameraState.showFocusAnimation && _tapFocusOffset != null)
                            FocusIndicator(point: _tapFocusOffset!),
                        ],
                      ),
                    );
                  },
                ),

                // 2. Top Bar: Flash Toggle, Active Batch Tag, Upload Manager Nav
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Flash Toggle Button (disabled if no permission)
                      _buildGlassIconButton(
                        icon: config.isFlashEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: !_hasCameraPermission
                            ? Colors.white24
                            : (config.isFlashEnabled
                                ? Colors.amberAccent
                                : Colors.white),
                        onTap: !_hasCameraPermission
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                context.read<CameraBloc>().add(ToggleFlashEvent());
                              },
                      ),

                      // Active Batch Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.cyanAccent.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.cyanAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cameraState.activeBatch != null
                                  ? '${cameraState.activeBatch!.name.substring(0, 10)}... (${cameraState.activeBatch!.images.length} photos)'
                                  : 'STARTING BATCH...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Upload Manager Navigation Icon with Queue Badge
                      BlocBuilder<SyncBloc, SyncState>(
                        builder: (context, syncState) {
                          final pendingCount = syncState.pendingCount;

                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildGlassIconButton(
                                icon: Icons.cloud_sync_outlined,
                                color: syncState.isOnline
                                    ? AppTheme.cyanAccent
                                    : AppTheme.statusFailed,
                                onTap: () {
                                  AppRouter.navigateToUploadManager(context);
                                },
                              ),
                              if (pendingCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.statusFailed,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$pendingCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 3. Right Side: Vertical Zoom Slider & Discrete Ratios (0.5x, 1x, 2x)
                Positioned(
                  right: 16,
                  top: 100,
                  bottom: 140,
                  child: Center(
                    child: AbsorbPointer(
                      absorbing: !_hasCameraPermission,
                      child: Opacity(
                        opacity: !_hasCameraPermission ? 0.35 : 1.0,
                        child: ZoomControlBar(
                          currentZoom: config.currentZoom,
                          minZoom: config.minZoom,
                          maxZoom: config.maxZoom,
                          availableRatios: config.availableRatios,
                          onZoomChanged: (zoom) {
                            setState(() {
                              _currentScale = zoom;
                            });
                            context.read<CameraBloc>().add(ChangeZoomEvent(zoom));
                          },
                          onRatioSelected: (ratio) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _currentScale = ratio;
                            });
                            context.read<CameraBloc>().add(SetZoomRatioEvent(ratio));
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. Bottom Controls: New Batch, Capture Shutter, Upload Manager Quick Button
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sub-status info
                      if (isSimulated && _hasCameraPermission)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'SIMULATED SENSOR (EMULATOR / LAB MODE)',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // "NEW BATCH" Button (disabled if no permission)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGlassIconButton(
                                icon: Icons.create_new_folder_outlined,
                                color: !_hasCameraPermission
                                    ? Colors.white24
                                    : Colors.white,
                                size: 48,
                                iconSize: 22,
                                onTap: !_hasCameraPermission
                                    ? null
                                    : () {
                                        HapticFeedback.mediumImpact();
                                        context
                                            .read<CameraBloc>()
                                            .add(NewBatchEvent());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Started new capture batch'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'NEW BATCH',
                                style: TextStyle(
                                  color: !_hasCameraPermission
                                      ? Colors.white30
                                      : Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Large Shutter Button (disabled if no permission)
                          GestureDetector(
                            onTap: (!_hasCameraPermission || cameraState.isCapturing)
                                ? null
                                : () {
                                    HapticFeedback.heavyImpact();
                                    context
                                        .read<CameraBloc>()
                                        .add(CapturePhotoEvent());
                                  },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer shutter ring
                                Container(
                                  width: 82,
                                  height: 82,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: !_hasCameraPermission
                                          ? Colors.white24
                                          : (cameraState.isCapturing
                                              ? AppTheme.cyanAccent
                                              : Colors.white),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                // Inner solid button
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: cameraState.isCapturing ? 62 : 68,
                                  height: cameraState.isCapturing ? 62 : 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: !_hasCameraPermission
                                        ? Colors.white12
                                        : (cameraState.isCapturing
                                            ? AppTheme.cyanGlow
                                            : Colors.white),
                                    boxShadow: !_hasCameraPermission
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: AppTheme.cyanAccent
                                                  .withOpacity(0.4),
                                              blurRadius: 16,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: cameraState.isCapturing
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      Colors.black),
                                            ),
                                          )
                                        : Icon(
                                            !_hasCameraPermission
                                                ? Icons.videocam_off_outlined
                                                : Icons.camera_alt,
                                            color: !_hasCameraPermission
                                                ? Colors.white38
                                                : Colors.black,
                                            size: 28,
                                          ),
                                  ),
                                ),

                                // Photo burst count badge
                                if (_hasCameraPermission &&
                                    cameraState.activeBatch != null &&
                                    cameraState.activeBatch!.images.isNotEmpty)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cyanAccent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${cameraState.activeBatch!.images.length}',
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // "SYNC MANAGER" Button
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGlassIconButton(
                                icon: Icons.cloud_upload_outlined,
                                color: AppTheme.cyanAccent,
                                size: 48,
                                iconSize: 22,
                                onTap: () {
                                  AppRouter.navigateToUploadManager(context);
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'SYNC QUEUE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHardwarePreview(CameraController controller) {
    return Center(
      child: CameraPreview(controller),
    );
  }

  Widget _buildSimulatedViewfinder(CameraConfigEntity config) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
            Color(0xFF020617),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center Reticle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.cyanAccent.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(70),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.cyanGlow.withOpacity(0.6),
                width: 1.5,
              ),
            ),
          ),
          Positioned(
            bottom: 180,
            child: Text(
              'MAGNIFICATION: ${config.currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: AppTheme.cyanAccent,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedViewfinder() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.redAccent.withValues(alpha: 0.12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Colors.redAccent,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'CAMERA PERMISSION REQUIRED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera access is currently disabled. All capture, flash, and zoom actions are unavailable until permission is granted.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.security, size: 18),
              label: const Text(
                'Give Permission',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _showPermissionDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingViewfinder() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(AppTheme.cyanAccent),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return IgnorePointer(
      child: CustomPaint(
        painter: ViewfinderGridPainter(),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    double size = 44,
    double iconSize = 22,
  }) {
    final isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

class ViewfinderGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 1.0;

    final x1 = size.width / 3;
    final x2 = (size.width / 3) * 2;
    final y1 = size.height / 3;
    final y2 = (size.height / 3) * 2;

    // Vertical rule of thirds lines
    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), paint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), paint);

    // Horizontal rule of thirds lines
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
