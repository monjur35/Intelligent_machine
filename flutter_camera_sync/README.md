# AeroSync — Resilient Camera & Hardware Telemetry Sync Engine

AeroSync is an enterprise-grade Flutter module delivering deep hardware camera controls and an offline-first resilient telemetry synchronization engine.

---

## Key Highlights

- **Hardware Camera Integration**:
  - Continuous pinch-to-zoom and precision vertical slider.
  - Hardware-tailored discrete zoom ratios (`0.5x`, `1.0x`, `2.0x`, `3.0x`/`5.0x`) computed dynamically from physical sensor capabilities.
  - Multi-back camera lens switching (`L1`, `L2`, ...) for devices with multiple physical rear sensors.
  - Interactive tap-to-focus and exposure metering with a synchronized pulsing reticle animation.
  - Resilient camera hardware lifecycle management (`RouteAware` and `WidgetsBindingObserver`) releasing camera sensors on route navigation or app pause/backgrounding to eliminate sensor contention and battery drain.

- **Resilient Offline-First Sync Engine**:
  - Persistent SQLite storage (`sqflite`) tracking batches and individual photo assets (`batch_images`).
  - Automatic re-queueing of batches when new photos are captured into existing batches.
  - Process crash recovery: automatically recovers batches stuck in `syncing` state on startup or background wake.
  - Mutual exclusion lock (`acquireSyncLock` lease) preventing race conditions between foreground UI uploads and headless background workers.
  - Headless background retries via Android `WorkManager` with exponential backoff and network constraints.
  - Cross-isolate outage simulation: failure simulation toggle is persisted in SQLite, ensuring background workers obey network drop simulations synchronously with the UI.

---

## Architecture & State Management

Built strictly following **Clean Architecture** and **BLoC (Business Logic Component)**:

```
lib/
├── core/               # Themes, navigation (AppRouter), network info
├── data/               # SQLite database helper, repositories, models, mock remote API
├── domain/             # Entities (Batch, Image, CameraConfig), Repository interfaces, Use Cases
├── presentation/       # BLoCs (CameraBloc, SyncBloc), Screens, Widgets
└── services/           # WorkManager background task dispatcher
```

---

## Running & Testing

```bash
# Navigate to module
cd flutter_camera_sync

# Fetch dependencies
flutter pub get

# Verify code quality & analyze
flutter analyze

# Run unit and widget tests
flutter test

# Run application
flutter run
```
