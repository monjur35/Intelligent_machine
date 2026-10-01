import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ZoomControlBar extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final List<double> availableRatios;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onRatioSelected;

  const ZoomControlBar({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.availableRatios,
    required this.onZoomChanged,
    required this.onRatioSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Standard discrete ratio buttons
    final ratios = availableRatios.isNotEmpty ? availableRatios : [0.5, 1.0, 2.0];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zoom level indicator
          Text(
            '${currentZoom.toStringAsFixed(1)}x',
            style: const TextStyle(
              color: AppTheme.cyanGlow,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Vertical zoom slider
          SizedBox(
            height: 140,
            width: 36,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: AppTheme.cyanAccent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppTheme.cyanGlow,
                  overlayColor: AppTheme.cyanAccent.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: currentZoom.clamp(minZoom, maxZoom),
                  min: minZoom,
                  max: maxZoom,
                  onChanged: onZoomChanged,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Discrete ratio quick buttons
          ...ratios.map((ratio) {
            final isSelected = (currentZoom - ratio).abs() < 0.15;
            final label = ratio == 0.5
                ? '.5'
                : ratio == 1.0
                    ? '1x'
                    : ratio == 2.0
                        ? '2x'
                        : '${ratio.toStringAsFixed(1)}x';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: InkWell(
                onTap: () => onRatioSelected(ratio),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.cyanAccent
                        : Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSelected ? AppTheme.cyanGlow : Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
