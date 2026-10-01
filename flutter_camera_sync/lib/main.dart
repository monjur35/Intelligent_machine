import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/network_info.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/camera/camera_data_source.dart';
import 'data/datasources/local/database_helper.dart';
import 'data/datasources/remote/mock_upload_api.dart';
import 'data/repositories/camera_repository_impl.dart';
import 'data/repositories/sync_repository_impl.dart';
import 'presentation/blocs/camera/camera_bloc.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/screens/camera_preview_screen.dart';
import 'presentation/screens/upload_manager_screen.dart';
import 'services/background_sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkBg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Background Sync Engine via WorkManager
  await BackgroundSyncService().initialize();

  // Core singletons & repositories
  final dbHelper = DatabaseHelper.instance;
  final remoteApi = MockUploadApiClient();
  final networkInfo = NetworkInfoImpl();

  final cameraRepository = CameraRepositoryImpl(
    dataSource: CameraDataSourceImpl(),
  );

  final syncRepository = SyncRepositoryImpl(
    dbHelper: dbHelper,
    remoteApi: remoteApi,
    networkInfo: networkInfo,
  );

  runApp(
    AeroSyncApp(
      cameraRepository: cameraRepository,
      syncRepository: syncRepository,
      networkInfo: networkInfo,
      remoteApi: remoteApi,
    ),
  );
}

class AeroSyncApp extends StatelessWidget {
  final CameraRepositoryImpl cameraRepository;
  final SyncRepositoryImpl syncRepository;
  final NetworkInfo networkInfo;
  final RemoteSyncApi remoteApi;

  const AeroSyncApp({
    super.key,
    required this.cameraRepository,
    required this.syncRepository,
    required this.networkInfo,
    required this.remoteApi,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CameraBloc>(
          create: (_) => CameraBloc(
            cameraRepository: cameraRepository,
            syncRepository: syncRepository,
          ),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => SyncBloc(
            syncRepository: syncRepository,
            networkInfo: networkInfo,
            remoteApi: remoteApi,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'AeroSync Camera & Sync Engine',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const CameraPreviewScreen(),
          '/upload-manager': (context) => const UploadManagerScreen(),
        },
      ),
    );
  }
}
