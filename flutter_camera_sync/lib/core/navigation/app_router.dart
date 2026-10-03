import 'package:flutter/material.dart';
import '../../presentation/screens/camera_preview_screen.dart';
import '../../presentation/screens/upload_manager_screen.dart';

/// Centralized route name constants for the application.
abstract final class AppRoutes {
  static const String initial = cameraPreview;
  static const String cameraPreview = '/';
  static const String uploadManager = '/upload-manager';
}

/// Dedicated navigation and route manager class.
class AppRouter {
  AppRouter._();

  /// Global navigator key allowing context-less navigation when needed.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Route map for standard static route declarations.
  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.cameraPreview: (context) => const CameraPreviewScreen(),
        AppRoutes.uploadManager: (context) => const UploadManagerScreen(),
      };

  /// Route generator handling standard & unknown routes dynamically.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.cameraPreview:
        return _buildRoute(
          settings: settings,
          builder: (_) => const CameraPreviewScreen(),
        );

      case AppRoutes.uploadManager:
        return _buildRoute(
          settings: settings,
          builder: (_) => const UploadManagerScreen(),
        );

      default:
        return _buildRoute(
          settings: settings,
          builder: (_) => _buildUnknownRouteScreen(settings.name),
        );
    }
  }

  /// Platform-compliant page route builder.
  static PageRoute<dynamic> _buildRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: builder,
    );
  }

  /// Fallback UI displayed when an undefined route is requested.
  static Widget _buildUnknownRouteScreen(String? routeName) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 64,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 16),
              Text(
                'No route defined for "$routeName"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (navigatorKey.currentState?.canPop() ?? false) {
                    navigatorKey.currentState?.pop();
                  } else {
                    navigatorKey.currentState
                        ?.pushReplacementNamed(AppRoutes.initial);
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Static Navigation Helpers ---

  /// Retrieves the current BuildContext from the navigator key if available.
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navigates to a named route.
  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    BuildContext? context,
    Object? arguments,
  }) {
    final nav = context != null
        ? Navigator.of(context)
        : navigatorKey.currentState;
    return nav?.pushNamed<T>(routeName, arguments: arguments) ??
        Future.value(null);
  }

  /// Replaces the current route with a named route.
  static Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    BuildContext? context,
    TO? result,
    Object? arguments,
  }) {
    final nav = context != null
        ? Navigator.of(context)
        : navigatorKey.currentState;
    return nav?.pushReplacementNamed<T, TO>(
          routeName,
          result: result,
          arguments: arguments,
        ) ??
        Future.value(null);
  }

  /// Pops the top-most route off the navigation stack.
  static void pop<T extends Object?>({
    BuildContext? context,
    T? result,
  }) {
    final nav = context != null
        ? Navigator.of(context)
        : navigatorKey.currentState;
    nav?.pop<T>(result);
  }

  /// Quick helper to navigate to the Upload Manager screen.
  static Future<void> navigateToUploadManager([BuildContext? context]) {
    return pushNamed(AppRoutes.uploadManager, context: context);
  }
}
