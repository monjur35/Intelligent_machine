import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../data/datasources/local/database_helper.dart';
import '../data/datasources/remote/mock_upload_api.dart';
import '../data/repositories/sync_repository_impl.dart';

const String syncUploadQueueTask = "com.monjur.aerosync.sync_upload_queue";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('[BackgroundSyncWorker] Executing headless task: $taskName');
      final dbHelper = DatabaseHelper.instance;
      final remoteApi = MockUploadApiClient();
      final syncRepo = SyncRepositoryImpl(
        dbHelper: dbHelper,
        remoteApi: remoteApi,
      );

      await syncRepo.processSyncQueue();
      debugPrint('[BackgroundSyncWorker] Queue processed successfully in background.');
      return Future.value(true);
    } catch (e, stack) {
      debugPrint('[BackgroundSyncWorker] Background task error: $e\n$stack');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Workmanager is supported on Android and iOS
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );

        // Register periodic background sync when connected to network
        await Workmanager().registerPeriodicTask(
          "aerosync-periodic-sync",
          syncUploadQueueTask,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          existingWorkPolicy: ExistingWorkPolicy.update,
        );
        _isInitialized = true;
        debugPrint('[BackgroundSyncWorker] Registered periodic background sync task.');
      } catch (e) {
        debugPrint('[BackgroundSyncWorker] WorkManager init warning: $e');
      }
    }
  }

  Future<void> triggerImmediateSync() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Workmanager().registerOneOffTask(
          "aerosync-oneoff-${DateTime.now().millisecondsSinceEpoch}",
          syncUploadQueueTask,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
      } catch (e) {
        debugPrint('[BackgroundSyncWorker] One-off sync scheduling warning: $e');
      }
    }
  }
}
