# Master Project Implementation Plan
**Project Title**: **GeoPulse & AeroSync**
*Enterprise Geo-Fenced Attendance & Resilient Hardware Camera Sync Engine*

---

## 1. Executive Summary & Objective

This project addresses the **Senior App Developer Technical Assessment** requirements, demonstrating senior-level proficiency across:
1. **Native Android (Modern Jetpack Compose)**: High-accuracy geo-fenced attendance tracking, real-time reactive GPS location stream via Kotlin Flow, DataStore persistence, and **MVVM with Clean Architecture** matching the provided Figma/screenshot specification.
2. **Flutter (Clean Architecture + MVVM/BLoC)**: Deep camera hardware integration (pinch-to-zoom, slider, discrete zoom ratios, tap-to-focus animation), batch photo capture, and an offline-first resilient sync engine with background retries (`workmanager` + `connectivity_plus` + local queue persistence) built with **MVVM and Clean Architecture**.
3. **Engineering Excellence**: Production-grade architecture, strict separation of concerns (Data, Domain, Presentation), testability, graceful permission handling, and comprehensive documentation adhering to the assessment guidelines.

---

## 2. Technology Stack & Key Libraries

| Component | Native Android Task (Task 1) | Flutter Task (Task 2) |
| :--- | :--- | :--- |
| **Language** | Kotlin 2.2+ (Coroutines & Kotlin Flow) | Dart 3.9+ |
| **UI Framework** | Jetpack Compose (Material 3) | Flutter Framework |
| **Architecture** | **MVVM with Clean Architecture** | **MVVM with Clean Architecture** |
| **State Management** | Android `ViewModel` + Kotlin `StateFlow` | Flutter `BLoC` / `Cubit` / `ChangeNotifier` as ViewModels |
| **Hardware APIs** | Google Play Services Location (`FusedLocationProviderClient`) | `camera` plugin (CameraX/AVFoundation) |
| **Local Persistence** | Jetpack Preferences DataStore / Room | SQLite (`sqflite`) / Hive |
| **Background / Sync** | Coroutines & Lifecycle-aware collectors | `workmanager`, `connectivity_plus` |
| **Network & Mocking**| Offline-first repository pattern | Resilient Mock API Engine (pluggable HTTP client) |

---

## 3. Project Structure & Clean Architecture Layers

```text
EmployeeAttendance/
├── app/                                # Task 1: Native Android (Jetpack Compose)
│   ├── src/main/java/com/monjur/employeeattendance/
│   │   ├── data/                       # DATA LAYER: Data sources, Repositories, Entities
│   │   │   ├── local/                  # DataStore / Room (Office location & Attendance logs)
│   │   │   ├── location/               # LocationClient, FusedLocationProvider wrapper
│   │   │   └── repository/             # AttendanceRepositoryImpl, LocationRepositoryImpl
│   │   ├── domain/                     # DOMAIN LAYER: Business Logic, Models, Use Cases
│   │   │   ├── model/                  # OfficeLocation, AttendanceRecord, GeofenceStatus
│   │   │   ├── repository/             # Interface contracts (AttendanceRepository, LocationRepository)
│   │   │   └── usecase/                # SaveOfficeLocationUseCase, ObserveLocationUseCase, etc.
│   │   ├── presentation/               # PRESENTATION LAYER: MVVM Pattern
│   │   │   ├── viewmodel/              # AttendanceViewModel (exposes StateFlow<AttendanceUiState>)
│   │   │   ├── state/                  # AttendanceUiState, AttendanceUiEvent
│   │   │   ├── components/             # DistanceMeterGauge, OfficeContextCard, StatusBadge
│   │   │   └── AttendanceScreen.kt     # Jetpack Compose View
│   │   ├── utils/                      # PermissionHandler, DistanceFormatter, SimulationEngine
│   │   └── MainActivity.kt
│   └── build.gradle.kts
│
├── flutter_camera_sync/                # Task 2: Flutter Camera & Resilient Sync Engine
│   ├── lib/
│   │   ├── core/                       # Constants, Themes, NetworkInfo, Errors
│   │   ├── data/                       # DATA LAYER: Data sources & Model mappers
│   │   │   ├── datasources/            # LocalDatabase (SQFlite/Hive), MockSyncApi
│   │   │   ├── models/                 # BatchModel, ImageMetadataModel
│   │   │   └── repositories/           # CameraRepositoryImpl, SyncRepositoryImpl
│   │   ├── domain/                     # DOMAIN LAYER: Pure Dart entities & UseCases
│   │   │   ├── entities/               # BatchEntity, SyncStatus, CameraConfig
│   │   │   ├── repositories/           # Contract definitions
│   │   │   └── usecases/               # CaptureBatchUseCase, ProcessSyncQueueUseCase, etc.
│   │   ├── presentation/               # PRESENTATION LAYER: MVVM (View & ViewModel/Bloc)
│   │   │   ├── viewmodels/             # CameraViewModel/Bloc, SyncViewModel/Bloc
│   │   │   ├── state/                  # CameraUiState, SyncUiState
│   │   │   ├── screens/
│   │   │   │   ├── camera_preview_screen.dart   # Camera Viewfinder View
│   │   │   │   └── upload_manager_screen.dart   # Telemetry & Upload Manager View
│   │   │   └── widgets/                # FocusTargetIndicator, ZoomControlBar, BatchCard
│   │   ├── services/
│   │   │   └── background_sync_worker.dart      # WorkManager task definition
│   │   └── main.dart
│   └── pubspec.yaml
│
├── docs/                               # Architectural & Design specifications
│   ├── PROJECT_PLAN.md
│   ├── TASK1_NATIVE_ANDROID_SPEC.md
│   └── TASK2_FLUTTER_SYNC_SPEC.md
└── README.md                           # Master README matching Assessment Criteria
```

---

## 4. Phased Implementation Roadmap

```mermaid
graph TD
    subgraph Phase 1: Planning & Setup
        P1A[Architecture Spec & MD Docs] --> P1B[Configure Android Dependencies]
        P1A --> P1C[Initialize Flutter Sub-Project]
    end

    subgraph Phase 2: Task 1 - Native Android Geofence
        P2A[Location & DataStore Engine] --> P2B[Geofence MVVM ViewModel & Clean Architecture]
        P2B --> P2C[Pixel-Perfect Compose UI]
        P2C --> P2D[Testing & Location Simulation Mode]
    end

    subgraph Phase 3: Task 2 - Flutter Camera UI
        P3A[Camera Controller & Gestures] --> P3B[Zoom Slider, Ratios & Tap-to-Focus]
        P3C[Batch Photo Capturing] --> P3B
        P3C --> P3D[Upload Manager Telemetry UI]
    end

    subgraph Phase 4: Task 2 - Resilient Sync Engine
        P4A[Local Queue Persistence SQLite/Hive] --> P4B[Connectivity Monitoring & Mock API]
        P4B --> P4C[WorkManager Background Auto-Retry]
    end

    subgraph Phase 5: Verification, Docs & Deliverables
        P5A[Build & Lint Verification] --> P5B[Comprehensive README with AI Disclosures]
        P5B --> P5C[APK Build & Packaging]
    end

    Phase 1 --> Phase 2
    Phase 2 --> Phase 3
    Phase 3 --> Phase 4
    Phase 4 --> Phase 5
```

### Phase 1: Environment & Architecture Setup
- [x] Create formal specification documents (`PROJECT_PLAN.md`, `TASK1_NATIVE_ANDROID_SPEC.md`, `TASK2_FLUTTER_SYNC_SPEC.md`).
- Update Android dependencies: `play-services-location`, `androidx.datastore:datastore-preferences`, `lifecycle-viewmodel-compose`, Compose Icons.
- Initialize Flutter project `flutter_camera_sync` with `camera`, `flutter_bloc`, `workmanager`, `connectivity_plus`, `sqflite`/`path_provider`.

### Phase 2: Task 1 - Native Android Geo-Fenced Attendance System
- **Location Stream**: Implement `LocationClient` wrapping `FusedLocationProviderClient` with `callbackFlow` emitting location updates with high accuracy.
- **Persistence**: Preferences DataStore storing `office_latitude`, `office_longitude`, `office_name`, and timestamp of office setup, plus attendance history.
- **Geofence Calculation**: Domain use case calculating distance in meters using Haversine / `Location.distanceBetween` and determining if within `<= 50m`.
- **UI (Jetpack Compose)**:
  - Header: Back button + "Attendance".
  - Step 1: Office Context card with latitude/longitude display and "Set Office Location" button.
  - Radial distance gauge matching screenshot: circular progress ring displaying numeric distance (`120m AWAY`), color-coded `• OUT OF RANGE` (red) vs `• IN RANGE` (green).
  - Validation check: "Mark Attendance" button unlocked only when `<= 50m`.
  - Shift/Availability indicator ("AVAILABLE 09:00 AM - 10:30 AM").
  - Location Simulation toggle (allows reviewers to easily test in-range vs out-of-range).

### Phase 3: Task 2 - Flutter Advanced Camera UI
- **Camera Initialization**: Auto-detect rear camera with maximum resolution.
- **Zoom System**:
  - Pinch-to-zoom using `ScaleGestureRecognizer`.
  - Vertical smooth slider with active level indicator.
  - Discrete zoom preset pills (`0.5x`, `1x`, `2x` or min/max capabilities).
- **Manual Tap-to-Focus**:
  - Tap on viewfinder computes relative offset `(dx, dy)`.
  - Calls `setFocusPoint()` and `setExposurePoint()`.
  - Displays animated focus square with scaling and auto-fade animation.
- **Batch Capture**:
  - Shutter button with animated capture feedback.
  - Batch accumulator showing count of captured photos in current batch.
  - Batch review sheet / transition to Upload Manager.

### Phase 4: Task 2 - Resilient Sync Engine
- **Local Persistence**: Database table for Batches and Batch Items (image path, thumbnail, file size, timestamp, retry count, status: `queued`, `syncing`, `synced`, `failed`).
- **Resilient Upload Engine**:
  - Mock Network Client with simulated latency, variable network failure simulation, and low-bandwidth timeouts.
  - Connection change listener using `connectivity_plus`: immediately triggers sync when internet is restored.
  - Background worker with `workmanager`: periodic/triggered background retries without user intervention.
- **Upload Manager UI**:
  - Dark sleek telemetry dashboard matching reference screenshot.
  - Real-time sync status ("SYNC STATUS: IDLE / RUNNING / RETRYING").
  - List of pending and synced batches with progress indicators.
  - Action buttons: "START NEW UPLOAD BATCH", "UPLOAD BATCH (N)", "SIMULATE NETWORK FAIL/RESTORE".

### Phase 5: Documentation, Verification & Release
- Verify builds: Android Gradle build (`./gradlew assembleDebug/assembleRelease`) and Flutter build (`flutter build apk`).
- Generate complete, professional `README.md` containing:
  - Project Title & Architecture breakdown.
  - BLoC & Flow state management explanation.
  - Generative AI prompt logs and architectural design decisions.
  - Complete instructions on how to build and run both projects.
  - Verification checklist for all assessment requirements.
