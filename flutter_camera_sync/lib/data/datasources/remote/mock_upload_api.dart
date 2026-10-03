import 'dart:async';
import 'dart:io';
import '../../models/batch_model.dart';

import '../local/database_helper.dart';

abstract class RemoteSyncApi {
  Future<bool> uploadBatch(BatchModel batch);
  void setForceFailure(bool force);
  bool get forceFailure;
}

class MockUploadApiClient implements RemoteSyncApi {
  final DatabaseHelper? dbHelper;
  bool _forceFailure = false;

  MockUploadApiClient({DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  bool get forceFailure => _forceFailure;

  @override
  void setForceFailure(bool force) {
    _forceFailure = force;
    dbHelper?.setConfig('force_failure', force ? 'true' : 'false');
  }

  @override
  Future<bool> uploadBatch(BatchModel batch) async {
    // Check shared config so background WorkManager isolate also obeys the outage simulation
    final isPersistedForced = await dbHelper?.getConfig('force_failure') == 'true';
    final shouldFail = _forceFailure || isPersistedForced;

    // -------------------------------------------------------------------------
    // PRODUCTION REST API IMPLEMENTATION (Commented out per assessment instructions)
    // -------------------------------------------------------------------------
    /*
    final uri = Uri.parse('https://api.enterprise-telemetry.com/v1/sync/batches');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer YOUR_SECURE_TOKEN';
    request.fields['batch_id'] = batch.id;
    request.fields['batch_name'] = batch.name;
    request.fields['created_at'] = batch.createdAt.toIso8601String();

    for (int i = 0; i < batch.images.length; i++) {
      final img = batch.images[i];
      final file = File(img.filePath);
      if (await file.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            img.filePath,
            filename: '${batch.id}_img_$i.jpg',
          ),
        );
      }
    }

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else {
      throw HttpException('Server error: ${response.statusCode}');
    }
    */

    // -------------------------------------------------------------------------
    // RESILIENT MOCK API ENGINE (Simulating realistic network upload & latency)
    // -------------------------------------------------------------------------
    await Future.delayed(const Duration(milliseconds: 1400));

    // If simulated failure or device forced failure is toggled
    if (shouldFail) {
      throw const SocketException("Simulated Network Drop / Low Bandwidth Timeout");
    }

    // Success response hard-coded per assessment instructions
    return true;
  }
}
