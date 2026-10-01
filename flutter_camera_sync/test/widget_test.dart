import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_camera_sync/domain/entities/batch_entity.dart';
import 'package:flutter_camera_sync/domain/entities/batch_image_entity.dart';
import 'package:flutter_camera_sync/presentation/widgets/status_pill.dart';
import 'package:flutter_camera_sync/presentation/widgets/zoom_control_bar.dart';

void main() {
  group('Domain Entities Tests', () {
    test('BatchEntity totalSizeBytes calculates correctly across images', () {
      final img1 = BatchImageEntity(
        id: 'img-1',
        batchId: 'batch-1',
        filePath: '/tmp/img1.jpg',
        fileSizeBytes: 1024,
        capturedAt: DateTime.now(),
      );
      final img2 = BatchImageEntity(
        id: 'img-2',
        batchId: 'batch-1',
        filePath: '/tmp/img2.jpg',
        fileSizeBytes: 2048,
        capturedAt: DateTime.now(),
      );

      final batch = BatchEntity(
        id: 'batch-1',
        name: 'BATCH_TEST',
        createdAt: DateTime.now(),
        images: [img1, img2],
        status: BatchStatus.queued,
      );

      expect(batch.totalSizeBytes, equals(3072));
      expect(batch.images.length, equals(2));
      expect(batch.status, equals(BatchStatus.queued));
    });

    test('BatchEntity copyWith preserves and updates state immutably', () {
      final batch = BatchEntity(
        id: 'batch-2',
        name: 'BATCH_IMMUTABLE',
        createdAt: DateTime.now(),
        status: BatchStatus.queued,
        retryCount: 0,
      );

      final updated = batch.copyWith(
        status: BatchStatus.failed,
        retryCount: 1,
        errorMessage: 'Network timeout',
      );

      expect(updated.status, equals(BatchStatus.failed));
      expect(updated.retryCount, equals(1));
      expect(updated.errorMessage, equals('Network timeout'));
      expect(batch.status, equals(BatchStatus.queued));
      expect(batch.retryCount, equals(0));
    });
  });

  group('Presentation Widgets Tests', () {
    testWidgets('StatusPill displays correct status text and colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusPill(status: BatchStatus.synced),
          ),
        ),
      );

      expect(find.text('SYNCED'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('ZoomControlBar renders discrete ratio buttons',
        (WidgetTester tester) async {
      double selectedRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControlBar(
              currentZoom: 1.0,
              minZoom: 0.5,
              maxZoom: 4.0,
              availableRatios: const [0.5, 1.0, 2.0],
              onZoomChanged: (_) {},
              onRatioSelected: (ratio) {
                selectedRatio = ratio;
              },
            ),
          ),
        ),
      );

      expect(find.text('1x'), findsWidgets);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('.5'), findsOneWidget);

      await tester.tap(find.text('2x'));
      await tester.pump();
      expect(selectedRatio, equals(2.0));
    });
  });
}
