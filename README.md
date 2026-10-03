# GeoPulse & AeroSync — Mobile Engineering Technical Assessment

This monorepo delivers two enterprise-grade mobile systems developed for the Senior Mobile Developer Assessment:
1. **Task 1 — GeoPulse (Native Android / Kotlin Jetpack Compose)**: High-accuracy geo-fenced employee attendance system with real-time radial distance tracking, reactive Kotlin Flow location streams, office context calibration, and strict 50-meter geofence validation.
2. **Task 2 — AeroSync (Flutter / Dart)**: Advanced Camera Hardware Integration & Resilient Batch Sync Engine with viewfinder controls, hardware-tailored discrete ratio selection, multi-back lens switching, animated tap-to-focus, offline SQLite queue persistence, and headless WorkManager background synchronization with cross-isolate mutual exclusion locks.

---

## Deliverables & Release APKs

Pre-built binaries are available for direct review:
- **Task 1 (Native Android)**: [Download GeoPulse Release APK](https://github.com/monjur35/Intelligent_machine/releases/latest/download/geopulse-release.apk)
  *(Local build path: `app/build/outputs/apk/release/geopulse-release.apk`)*
- **Task 2 (Flutter App)**: [Download AeroSync Release APK](https://github.com/monjur35/Intelligent_machine/releases/latest/download/aerosync-release.apk)
  *(Local build path: `flutter_camera_sync/build/app/outputs/flutter-apk/aerosync-release.apk`)*

---

## 1. System Architecture & Approaches

Both applications strictly adhere to **Clean Architecture with MVVM (Model-View-ViewModel)** to guarantee decoupled layers, high testability, and zero crashes.

### Architectural Diagram

```mermaid
graph TD
    subgraph Presentation["Presentation Layer"]
        UI["Jetpack Compose / Flutter Widgets"]
        VM["ViewModel (StateFlow) / BLoC"]
        UI --> VM
    end

    subgraph Domain["Domain Layer (Core Business Rules)"]
        UC["Use Cases / Interactors"]
        REPO_INT["Repository Interfaces"]
        ENT["Pure Domain Entities"]
        UC --> REPO_INT
        UC --> ENT
    end

    subgraph Data["Data Layer (Infrastructure & I/O)"]
        REPO_IMPL["Repository Implementations"]
        LOCAL_DS["Preferences DataStore / SQLite (sqflite)"]
        REMOTE_HW["FusedLocationProvider / CameraX / WorkManager / MockApi"]
        REPO_IMPL --> LOCAL_DS
        REPO_IMPL --> REMOTE_HW
    end

    %% Cross-layer boundaries (Inward Dependencies)
    VM --> UC
    REPO_IMPL -.->|implements| REPO_INT
```

### Task 1: GeoPulse (Native Android)
- **UI & Presentation**: Built entirely in **Jetpack Compose** with Material 3 tokens.
  - Implements `WindowInsets.statusBars` and `navigationBarsPadding()` for edge-to-edge rendering without status bar overlapping across any screen cutout or aspect ratio.
  - Custom radial arc canvas (`DistanceArcMeter`) providing dynamic color feedback (emerald green within 50m, amber transition, crimson when out-of-range).
  - Cleaned navigation with back arrow removed for dedicated home/kiosk presence.
- **Dependency Injection**: **Dagger Hilt 2.51+** (`@HiltAndroidApp`, `@AndroidEntryPoint`, `@HiltViewModel`).
- **Location Trust & Geofencing**:
  - Enforces `ACCESS_FINE_LOCATION` to guarantee sub-meter accuracy required for a 50m geofence (rejects coarse-only fixes which yield 1–2 km uncertainty on Android 12+).
  - Rejects stale GPS fixes older than 15 seconds and filters out readings with accuracy uncertainty exceeding 30 meters.
  - Pure Kotlin Haversine algorithm fallback for mathematical verification.
- **Persistence & Integrity**:
  - Preferences DataStore for atomic persistence of office coordinates and timestamps.
  - Attendance history persistence tracking timestamps, coordinates, distance, and simulation flags (`isSimulated`).
  - Automatically restores today's check-in status on app startup and guards against duplicate attendance recordings on the same calendar day.
- **Reviewer Simulation Tool**: Integrated segment selector (`Live GPS`, `25m (In)`, `120m (Out)`) gated strictly behind `BuildConfig.DEBUG` so production releases are protected against geofence spoofing.

### Task 2: AeroSync (Flutter)
- **UI & Presentation**: Dark telemetry design aesthetic matching the assessment specification.
  - Interactive viewfinder with pinch-to-zoom and vertical zoom slider.
  - Hardware-tailored discrete ratio selector buttons (`0.5x`, `1.0x`, `2.0x`, `3.0x`/`5.0x`) derived from physical sensor capabilities.
  - Physical back-camera lens selector (`L1`, `L2`, ...) for devices with multiple physical rear lenses.
  - Animated tap-to-focus and exposure reticle (`FocusIndicator`) with easing curves.
  - Shutter button with burst count badge and haptic feedback.
- **Hardware Lifecycle Management**:
  - Implements `RouteAware` and `WidgetsBindingObserver` to release camera hardware when navigating to the Upload Manager or when the app is paused/backgrounded.
  - Eliminates `CAMERA_IN_USE` lockouts, image reader JNI memory leaks, and background battery drain.
- **State Management**: **flutter_bloc ^8.1.6** (`CameraBloc`, `SyncBloc`).
- **Offline Persistence & Queue**: **sqflite** database managing batches, image metadata (`batch_images`), file sizes, retry counters, and statuses (`queued`, `syncing`, `synced`, `failed`).
- **Resilient Sync Engine**:
  - Auto-requeues synced batches when new photos are added, ensuring zero photo loss.
  - Crash recovery: resets stale `syncing` batches to `queued` on startup and in background workers.
  - Cross-isolate mutual exclusion lock (`acquireSyncLock` lease) preventing race conditions between foreground UI uploads and background tasks.
  - Cross-isolate outage simulation: failure simulation toggle is persisted in SQLite, ensuring background workers obey network drop simulations synchronously with the UI.
  - Headless background retries via **WorkManager 0.8.0** with network constraints.
  - Real-time connectivity listening via `connectivity_plus` with automatic queue resumption when internet returns.

---

## 2. Generative AI Tools & Strategic Workflow

### Tools Used
- **Agentic AI**: Google DeepMind Antigravity IDE (Advanced Agentic Pair-Programming Engine).

### Essential Prompts & Outcomes

| # | Prompt Category | Real Prompt Excerpt | Engineer Correction / Manual Refinement |
|---|---|---|---|
| 1 | **Cross-Isolate Concurrency & Outage** | *"Resolve the isolate boundary gap where background sync operates independently of UI memory state: persist the network outage simulation across isolates via SQLite and introduce a database-backed distributed mutex to prevent concurrent sync collisions."* | Architected an `app_config` SQLite table providing cross-isolate persistence for the outage flag and an atomic lease-based mutex lock (`acquireSyncLock`). |
| 2 | **Geofence Trust & Attendance Idempotency** | *"Harden geofence validation and attendance integrity on Android: enforce ACCESS_FINE_LOCATION on Android 12+, discard stale or inaccurate GPS fixes exceeding threshold tolerances, and maintain persistent same-day check-in idempotency across cold restarts."* | Restricted `hasLocationPermission` to `ACCESS_FINE_LOCATION`, added 15s freshness filter and 25m accuracy filter, and added `observeAttendanceHistory` in `AttendanceViewModel`. |
| 3 | **Headless Background Sync Resilience** | *"Audit the WorkManager integration against background execution requirements: verify headless isolate bootstrapping with WidgetsFlutterBinding, enforce offline SQLite queuing with exponential backoff, and guarantee automatic resumption upon network connectivity changes."* | Added `WidgetsFlutterBinding.ensureInitialized()` in `callbackDispatcher`, configured exponential backoff, and injected SQLite-backed sync repo. |
| 4 | **Hardware Sensor Lifecycle Management** | *"Enforce strict camera sensor lifecycle management: hook into RouteAware and WidgetsBindingObserver to safely tear down the hardware controller on backgrounding or route transitions, avoiding native ImageReader buffer exhaustion and battery drain."* | Integrated `RouteAware` with `AppRouter.routeObserver` and `WidgetsBindingObserver`, dispatching `ReleaseCameraEvent` on push/paused and reinitializing on pop/resume. |
| 5 | **Full-Stack Memory & Resource Leak Audit** | *"Perform a comprehensive memory and resource leak audit across both Android (Kotlin) and Flutter (Dart) codebases: identify Context retention in long-lived singletons, unreleased GPS/camera hardware listeners during lifecycle transitions, and unmanaged timers or stream subscriptions."* | Audited both codebases: (1) Replaced direct Android Context references in `DefaultLocationClient`, `OfficePreferencesDataSource`, and `AttendanceLocalDataSource` with `applicationContext` to eliminate Activity leaks; (2) Added `stopObservingLocation()` on Compose `ON_PAUSE`/`ON_STOP` and `ViewModel.onCleared()` to halt GPS hardware polling in the background; (3) Added `ReleaseCameraEvent` on `CameraPreviewScreen.dispose()`; (4) Replaced unmanaged focus `Future.delayed` timer churn with a cancellable `Timer` in `CameraBloc`; (5) Implemented `dispose()` in `SyncRepositoryImpl` to cleanly close broadcast stream controllers. |

---

## 3. How to Run & Verify

### Prerequisites
- Android Studio Ladybug / Koala or up or CLI SDK tools
- OpenJDK 17 or 21
- Flutter SDK 3.35.x (`Dart 3.9+`)
- Connected Android Device or Emulator (API 30+)

### Setup Repository
```bash
git clone https://github.com/monjur35/Intelligent_machine.git
cd Intelligent_machine
```

### Task 1: Native Android (GeoPulse)
```bash
# Run unit tests
./gradlew testDebugUnitTest

# Build debug APK
./gradlew assembleDebug

# Build release APK with R8 code shrinking, ProGuard & obfuscation
./gradlew :app:assembleRelease

# Install and launch on connected emulator or device
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.monjur.employeeattendance/.MainActivity
```

### Task 2: Flutter App (AeroSync)
```bash
# Navigate to Flutter subproject
cd flutter_camera_sync

# Fetch dependencies
flutter pub get

# Verify static analysis (0 warnings, 0 deprecations)
flutter analyze

# Run unit and widget tests
flutter test

# Build production release APK with R8, ProGuard and Dart AOT code obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Run on connected device or emulator
flutter run
```

---

## 4. Visual Verification & Screenshots

### Task 1: GeoPulse (Native Android)

| Location Calibration & Out of Range | In-Range (24m) Geofence Active | Attendance Marked Success |
|:---:|:---:|:---:|
| ![GeoPulse Active](docs/screenshots/geopulse_active.png) | ![GeoPulse In-Range](docs/screenshots/geopulse_in_range.png) | ![GeoPulse Success](docs/screenshots/geopulse_marked_success.png) |

### Task 2: AeroSync (Flutter)

| Camera Viewfinder & Controls | Upload Manager Telemetry | Network Outage Retry Resilience | Auto-Resumption Synced |
|:---:|:---:|:---:|:---:|
| ![AeroSync Viewfinder](docs/screenshots/flutter_viewfinder_burst.png) | ![AeroSync Upload Manager](docs/screenshots/flutter_upload_manager.png) | ![AeroSync Outage Retry](docs/screenshots/flutter_network_failure_retry.png) | ![AeroSync Synced](docs/screenshots/flutter_auto_recovered.png) |

---

## 5. Repository Structure

```
EmployeeAttendance/
├── app/                                 # Task 1: Native Android App (Jetpack Compose)
│   ├── src/main/java/com/monjur/employeeattendance/
│   │   ├── di/                          # Dagger Hilt Dependency Injection Modules
│   │   ├── domain/                      # Models, UseCases, Repository Contracts
│   │   ├── data/                        # Preferences DataStore, FusedLocation Client
│   │   └── presentation/                # Jetpack Compose UI, ViewModels, StateFlow
│   ├── src/test/                        # Unit tests (UseCases & AttendanceViewModelTest)
│   ├── proguard-rules.pro               # Production ProGuard & R8 Optimization Rules
│   └── src/main/res/xml/                # Network Security Config & Data Extraction Rules
│
├── flutter_camera_sync/                 # Task 2: Flutter App (AeroSync)
│   ├── lib/
│   │   ├── core/                        # Themes, AppRouter, NetworkInfo
│   │   ├── domain/                      # Pure Dart Entities, Contracts, UseCases
│   │   ├── data/                        # SQLite DatabaseHelper, Models, Camera & API clients
│   │   ├── presentation/                # BLoC State (CameraBloc, SyncBloc), Viewfinder, Batch Cards
│   │   ├── services/                    # WorkManager Headless Background Worker
│   │   └── main.dart                    # App Entry Point & Dependency Injection
│   ├── android/app/proguard-rules.pro   # Flutter Engine & Plugin ProGuard Rules
│   ├── test/                            # Flutter Unit & Widget Tests
│   └── README.md                        # AeroSync Flutter Architecture Documentation
│
├── docs/                                # Technical Specifications & Screenshots
│   ├── PROJECT_PLAN.md                  # Master Engineering Roadmap
│   ├── TASK1_NATIVE_ANDROID_SPEC.md     # Android Architecture & Geofence Spec
│   ├── TASK2_FLUTTER_SYNC_SPEC.md       # Flutter Camera & Resilient Sync Spec
│   └── screenshots/                     # Telemetry & UI Verification Images
│
└── README.md                            # Technical Assessment Master Documentation
```

---

## 6. Security Architecture & Production Hardening

Both applications are configured with defense-in-depth security controls:

### 1. R8 Code Shrinking & Name Obfuscation
- Configured `isMinifyEnabled = true` in both Native Android and Flutter Android release targets.
- Strips unused classes, fields, and methods from application dex files.
- Renames classes, methods, and variables to unreadable single-character identifiers, making reverse engineering and decompilation via Jadx/APKTool ineffective.

### 2. Resource Shrinking
- Configured `isShrinkResources = true` in release builds to automatically remove unused assets, drawables, and XML layouts detected after R8 tree shaking.

### 3. Dart AOT Binary Obfuscation
- Flutter release builds are packaged with `--obfuscate --split-debug-info=build/app/outputs/symbols`.
- Strips Dart function names, symbol tables, and class metadata from the compiled Flutter ELF/snapshot binaries (`libapp.so`), storing debug symbols in isolated offline mapping files for crash de-obfuscation.

### 4. Custom ProGuard Keep Rules
- **Native Android (`app/proguard-rules.pro`)**: Keeps reflection-sensitive Dagger Hilt components, Jetpack Compose runtime/recomposers, DataStore Preferences serialization, Kotlin Coroutine dispatchers, and immutable domain models.
- **Flutter (`flutter_camera_sync/android/app/proguard-rules.pro`)**: Protects Flutter Engine JNI wrappers, WorkManager headless background workers (`Worker`, `ListenableWorker`), CameraX internals, and SQLite (`sqflite`).

### 5. Network Security & Cleartext Traffic Prohibition
- Configured `network_security_config.xml` with `<base-config cleartextTrafficPermitted="false">` and system CA trust anchors.
- Added `android:usesCleartextTraffic="false"` to both application manifests to block unencrypted HTTP transmission of telemetry, attendance records, or batch payloads.

### 6. Local Backup & Data Extraction Prevention
- Added `android:allowBackup="false"` to both Android manifests, preventing local database extraction of offline SQLite photos or DataStore logs through ADB backup (`adb backup`).

---

## 7. Known Limitations & Production Roadmap

While this implementation fulfills all assessment criteria and handles edge cases, production deployment would incorporate:
1. **Room Database for Android History**: Transitioning from delimited DataStore preferences to an Android Room DB with type-safe queries and SQLite migrations.
2. **Camera2 Multi-Camera Physical Lenses**: Leveraging OEM vendor extensions for physical ultra-wide switching on devices where CameraX aggregates lenses behind a single logical camera.
3. **Network Reachability Probe**: Supplementing `connectivity_plus` with an active DNS/HTTP reachability check to detect captive portals before triggering queue uploads.
