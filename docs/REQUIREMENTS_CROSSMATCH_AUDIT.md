# Requirements Crossmatch & Zero-Crash Robustness Audit

This document crossmatches every requirement from the **Senior App Developer Technical Assessment (Pages 1–4)** against our **Clean Architecture + MVVM** implementation design, with strict defensive programming rules to guarantee **zero crashes and no unhandled exceptions**.

---

## 1. Traceability Matrix: Assessment Requirements vs Implementation

| Assessment Requirement | PDF Page | Component / Module | Implementation & Robustness Strategy | Handled & Verified |
| :--- | :--- | :--- | :--- | :--- |
| **Creative Project Title** | Page 1 | Global | **GeoPulse & AeroSync**: Enterprise Geofenced Attendance & Offline-First Resilient Batch Sync Engine |  Yes |
| **State Management** | Page 1 | Android & Flutter | Native Android: **Kotlin Flow / StateFlow** in ViewModel.<br>Flutter: **BLoC / Cubit** in ViewModel. |  Yes |
| **Architecture** | Page 1 | Android & Flutter | **Clean Architecture + MVVM** (Separation of Data, Domain, and Presentation layers). |  Yes |
| **Local Storage** | Page 1 | Android & Flutter | Native Android: **Jetpack Preferences DataStore** (Office coordinates & preferences) + Local Attendance History.<br>Flutter: **SQLite (`sqflite`) / local persistence** for Batch & Image queue. |  Yes |
| **Graceful Error Handling** | Page 1 | Android & Flutter | Complete handling of permissions, GPS disabled, camera hardware limitations, and network timeouts. |  Yes |
| **Task 1: Office Setup** | Page 1, 2 | Native Android | Button "Set Office Location" fetches GPS coordinates with high accuracy and saves locally via DataStore. |  Yes |
| **Task 1: Geofence Validation** | Page 1, 2 | Native Android | "Mark Attendance" button is **strictly enabled only within 50m radius** of office coordinates; disabled when $>50\text{m}$. |  Yes |
| **Task 1: Real-Time Distance** | Page 1, 2 | Native Android | Continuous distance updates via `callbackFlow`, updating radial gauge in real time (e.g. `120m AWAY`). |  Yes |
| **Task 1: UI Matching Screenshot** | Page 2 | Native Android | Jetpack Compose UI matching reference: Top bar, Step 1 card with Lat/Lon chip, radial distance gauge, red/green status dot, padlock action card, "AVAILABLE 09:00 AM - 10:30 AM" label. |  Yes |
| **Task 2: Custom Camera UI** | Page 2, 3 | Flutter | `CameraPreviewScreen` with hardware viewfinder. |  Yes |
| **Task 2: Zoom Controls** | Page 2, 3 | Flutter | **3-Way Zoom**: Pinch-to-zoom gesture, vertical smooth slider, and rounded buttons (`0.5x`, `1x`, `2x`). |  Yes |
| **Task 2: Manual Focus** | Page 3 | Flutter | Tap-to-focus calling `setFocusPoint()` with animated pulsating focus square at tap coordinates. |  Yes |
| **Task 2: Batch Management** | Page 3 | Flutter | Capture batches of images, shutter counter badge, and "Upload Manager" showing pending uploads. |  Yes |
| **Task 2: Resilient Sync Engine** | Page 3 | Flutter | Background worker (`workmanager`) + connectivity listener (`connectivity_plus`). Images stay in queue on failure and **automatically retry without user intervention** when connection is restored. |  Yes |
| **Task 2: Mock API Integration** | Page 3 | Flutter | Pluggable Mock API with simulated latency/failures, accompanied by commented real HTTP multipart upload code. |  Yes |
| **Deliverable: Public GitHub Repo** | Page 3 | Delivery | Clean git commit structure, gitignore, organized multi-module layout. |  Yes |
| **Deliverable: Detailed README** | Page 3, 4 | Documentation | Covers: 1. Title/Desc, 2. Architecture & BLoC/Flow explanation, 3. Generative AI Usage & Prompts, 4. How to Run, 5. Screenshots. |  Yes |
| **Deliverable: Built Release APK** | Page 3 | Delivery | Build verification with Gradle assembleRelease / Flutter build apk. |  Yes |

---

## 2. Zero-Crash & Solid Exception Handling Matrix

To satisfy the explicit constraint: **"simple, clean code but solid, no crash or unhandled exception"**, the following defensive strategies are implemented:

### A. Native Android (Task 1) Defensive Strategies
1. **Location Permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`)**:
   - Never invoke `requestLocationUpdates` without checking `ContextCompat.checkSelfPermission`.
   - If denied: Display non-intrusive in-app banner explaining why location is required, with a direct button to request or navigate to Android App Settings.
   - Never crash if user denies permission repeatedly.
2. **GPS / Location Services Disabled**:
   - Check `LocationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)`.
   - If disabled: Do not throw `SecurityException` or hang; update UI state to `isGpsEnabled = false` and prompt user to enable Location Services.
3. **Office Location Not Yet Set**:
   - Initial state gracefully displays "Office location not set. Tap 'Set Office Location' to initialize geofence."
   - Distance gauge displays neutral/placeholder state without calculating distance against `null`.
4. **Lifecycle-Aware Location Stream**:
   - Wrap `LocationCallback` inside `callbackFlow` with `awaitClose { client.removeLocationUpdates(callback) }`.
   - Collect in Compose UI using `Lifecycle.State.STARTED` to prevent background memory leaks or battery drain.
5. **Distance & Math Safety**:
   - All distance calculations clamp to $\ge 0$.
   - Float-to-percentage math in radial canvas clamps progress to $[0.0f, 1.0f]$ avoiding arithmetic overflows.

### B. Flutter (Task 2) Defensive Strategies
1. **Camera Initialization & Hardware Constraints**:
   - Wrap `availableCameras()` and `controller.initialize()` in `try-catch (CameraException e)`.
   - If no physical camera exists (e.g. basic emulator), fail gracefully to a clean simulated viewfinder rather than crashing.
2. **Zoom Level Clamping**:
   - Query `controller.getMinZoomLevel()` and `getMaxZoomLevel()`.
   - If device does not support ultra-wide `0.5x`, automatically clamp to `minZoom` without throwing unhandled exceptions.
3. **Focus Point Safety**:
   - Guard `controller.setFocusPoint(offset)` with `try-catch` since some camera devices don't support dynamic point focusing.
4. **File I/O & Storage**:
   - Use `getApplicationDocumentsDirectory()` from `path_provider`.
   - Catch `FileSystemException` during thumbnail generation or batch saving.
5. **Background Sync Worker (`workmanager`)**:
   - The headless worker entrypoint wraps all operations in `runZonedGuarded` and top-level `try-catch`.
   - Any network failure or SQLite lock logs an error and returns `Future.value(false)` so WorkManager reschedules safely without crashing the OS background process.
6. **Network Connectivity Flaps**:
   - Debounce network connectivity events to avoid duplicate simultaneous upload triggers when transitioning between cellular and Wi-Fi.

---

## 3. Reviewer Testing & Simulation Feature

To make the app stand out and provide effortless evaluation:
- Both the real GPS stream and an instant **"Simulation Mode"** toggle are provided in the Native Android UI:
  - **Real GPS Mode**: Uses live device coordinates.
  - **In-Range Mock (25m)**: Instantly simulates standing within the 50m office perimeter.
  - **Out-of-Range Mock (120m)**: Simulates standing 120m away from the office.
- Allows anyone reviewing the code or APK to verify all states and animations in seconds without walking outside!
