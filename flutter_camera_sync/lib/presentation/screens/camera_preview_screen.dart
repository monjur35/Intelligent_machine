import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/camera_config_entity.dart';
import '../blocs/camera/camera_bloc.dart';
import '../blocs/camera/camera_event.dart';
import '../blocs/camera/camera_state.dart';
import '../blocs/sync/sync_bloc.dart';
import '../blocs/sync/sync_state.dart';
import '../widgets/focus_indicator.dart';
import '../widgets/zoom_control_bar.dart';
import 'upload_manager_screen.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  Offset? _tapFocusOffset;

  @override
  void initState() {
    super.initState();
    // Initialize hardware or simulated camera session
    context.read<CameraBloc>().add(InitializeCameraEvent());
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, CameraConfigEntity config) {
    if (details.scale == 1.0) return;
    final newZoom = (_baseScale * details.scale).clamp(config.minZoom, config.maxZoom);
    setState(() {
      _currentScale = newZoom;
    });
    context.read<CameraBloc>().add(ChangeZoomEvent(newZoom));
  }

  void _onTapDown(TapDownDetails details, BoxConstraints constraints) {
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
                // 1. Camera Viewfinder (Hardware Camera or Simulated Viewfinder)
                LayoutBuilder(
                  builder: (context, constraints) {
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
                      // Flash Toggle Button
                      _buildGlassIconButton(
                        icon: config.isFlashEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: config.isFlashEnabled
                            ? Colors.amberAccent
                            : Colors.white,
                        onTap: () {
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UploadManagerScreen(),
                                    ),
                                  );
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

                // 4. Bottom Controls: New Batch, Capture Shutter, Upload Manager Quick Button
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sub-status info
                      if (isSimulated)
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
                          // "NEW BATCH" Button
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildGlassIconButton(
                                icon: Icons.create_new_folder_outlined,
                                color: Colors.white,
                                size: 48,
                                iconSize: 22,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  context.read<CameraBloc>().add(NewBatchEvent());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Started new capture batch'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'NEW BATCH',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Large Shutter Button with Burst/Photo Count Badge
                          GestureDetector(
                            onTap: cameraState.isCapturing
                                ? null
                                : () {
                                    HapticFeedback.heavyImpact();
                                    context.read<CameraBloc>().add(CapturePhotoEvent());
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
                                      color: cameraState.isCapturing
                                          ? AppTheme.cyanAccent
                                          : Colors.white,
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
                                    color: cameraState.isCapturing
                                        ? AppTheme.cyanGlow
                                        : Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.cyanAccent.withOpacity(0.4),
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
                                              valueColor: AlwaysStoppedAnimation(
                                                  Colors.black),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.black,
                                            size: 28,
                                          ),
                                  ),
                                ),

                                // Photo burst count badge
                                if (cameraState.activeBatch != null &&
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const UploadManagerScreen(),
                                    ),
                                  );
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
    required VoidCallback onTap,
    double size = 44,
    double iconSize = 22,
  }) {
    return InkWell(
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
