# Task 1 Specification: Geo-Fenced Attendance System (Native Android)

## 1. Overview & Business Rules
- **Screen**: Single `AttendanceScreen` built entirely in Jetpack Compose.
- **Office Location Setup**: The user taps "Set Office Location", which fetches current GPS coordinates (`latitude`, `longitude`, `accuracy`, `timestamp`) with high priority via `FusedLocationProviderClient` and persists them to Preferences DataStore.
- **Geofencing Threshold**: Attendance check-in is allowed **only within a 50-meter radius** of the saved office location.
- **Real-Time Tracking & Feedback**:
  - The app subscribes to continuous location updates using a Kotlin `callbackFlow`.
  - Calculates real-time distance: $d = \text{distanceBetween}(\text{currentLat}, \text{currentLon}, \text{officeLat}, \text{officeLon})$.
  - Visual circular gauge indicating distance (e.g. `120m AWAY` or `24m AWAY`).
  - Status indicator:
    - Distance $> 50\text{m}$: Red dot `• OUT OF RANGE`, "Move within 50 meters of the designated office location to enable check-in.", "Mark Attendance" button is **disabled** with padlock icon.
    - Distance $\le 50\text{m}$: Green dot `• IN RANGE`, "You are within office premises. Attendance ready.", "Mark Attendance" button is **enabled**.
- **Attendance Submission**:
  - User taps "Mark Attendance".
  - Records check-in record (timestamp, coordinates, distance, status) into local persistence.
  - Displays check-in success dialog/bottom sheet and visual confirmation.

---

## 2. Architecture & Data Flow (MVVM with Clean Architecture)

```mermaid
flowchart TD
    subgraph Presentation Layer [MVVM Pattern in Jetpack Compose]
        View[AttendanceScreen - View]
        Gauge[DistanceMeterGauge]
        OfficeCard[OfficeContextCard]
        ActionBtn[MarkAttendanceButton]
        VM[AttendanceViewModel - ViewModel]
        State[StateFlow<AttendanceUiState>]
    end

    subgraph Domain Layer [Clean Architecture Business Logic & UseCases]
        SetLocUC[SaveOfficeLocationUseCase]
        GetLocUC[GetOfficeLocationUseCase]
        TrackLocUC[ObserveLocationUpdatesUseCase]
        CalcDistUC[CalculateDistanceUseCase]
        MarkAttUC[MarkAttendanceUseCase]
    end

    subgraph Data Layer [Repositories & DataSources]
        LocClient[LocationClient / FusedLocationProviderClient]
        DataStore[OfficePreferencesDataSource / DataStore]
        AttDao[AttendanceHistoryRepositoryImpl]
    end

    View -->|User Action: onSetLocationClick()| VM
    View -->|User Action: onMarkAttendanceClick()| VM
    VM -->|Exposes StateFlow| View
    VM --> SetLocUC & TrackLocUC & MarkAttUC
    TrackLocUC --> LocClient
    SetLocUC --> DataStore
    MarkAttUC --> AttDao
    LocClient -->|callbackFlow<Location>| TrackLocUC
```

---

## 3. Detailed UI Layout Matching Provided Mockup

The screen UI is divided into 4 primary sections matching the prompt screenshot:
1. **Top Bar**:
   - Navigation Icon (Back arrow).
   - Title: `Attendance` in bold typography.
2. **Step 1: Office Context Card**:
   - Title: `STEP 1: OFFICE CONTEXT` with active indicator badge.
   - GPS Preview Box: Stylized badge showing `Lat: 40.7128, Lon: -74.0068` (or current saved coordinates).
   - Informational text: *"To mark your attendance, ensure your current office location is correctly identified."*
   - Target Outlined Button: `Set Office Location` with crosshair icon.
3. **Radial Distance Meter**:
   - Circular arc gauge / ring with gradient stroke.
   - Center text: Big bold distance `120m` with subtitle `AWAY`.
   - Status Badge:
     - `• OUT OF RANGE` in red `#E53935` (when $> 50$m).
     - `• IN RANGE` in emerald green `#43A047` (when $\le 50$m).
   - Instruction: *"Move within 50 meters of the designated office location to enable check-in."*
4. **Attendance Action Section**:
   - Rounded container with padlock icon / unlocked checkmark icon.
   - Primary Pill Button: `Mark Attendance`.
     - Grayed out / disabled when distance $> 50$m or office location is not set.
     - Vibrant primary blue when $\le 50$m.
   - Availability Footnote: *"AVAILABLE 09:00 AM - 10:30 AM"* (with dynamic time check).
5. **Bonus Assessment Feature - Reviewer Simulation Panel**:
   - A discreet toggle bar allowing the evaluator to switch between:
     - Real GPS mode
     - Simulated In-Range mode ($25$m away)
     - Simulated Out-of-Range mode ($120$m away)
   - Enables instant verification on any emulator or device without needing physical movement.

---

## 4. MVVM Architecture Contracts

### UI State (Model)
```kotlin
data class AttendanceUiState(
    val isLoading: Boolean = false,
    val hasLocationPermission: Boolean = false,
    val isGpsEnabled: Boolean = true,
    val officeLocation: OfficeLocation? = null,
    val currentLocation: LocationCoordinates? = null,
    val distanceToOfficeMeters: Float? = null,
    val isWithinGeofence: Boolean = false, // distance <= 50.0m
    val isAttendanceMarked: Boolean = false,
    val attendanceTimestamp: Long? = null,
    val simulationMode: SimulationMode = SimulationMode.REAL_GPS,
    val errorMessage: String? = null,
    val successMessage: String? = null
)
```

### ViewModel Public Actions (MVVM Interaction)
```kotlin
class AttendanceViewModel(
    private val saveOfficeLocationUseCase: SaveOfficeLocationUseCase,
    private val getOfficeLocationUseCase: GetOfficeLocationUseCase,
    private val observeLocationUpdatesUseCase: ObserveLocationUpdatesUseCase,
    private val markAttendanceUseCase: MarkAttendanceUseCase
) : ViewModel() {
    val uiState: StateFlow<AttendanceUiState>

    fun onPermissionResult(isGranted: Boolean)
    fun onSetOfficeLocationClicked()
    fun onMarkAttendanceClicked()
    fun onSimulationModeChanged(mode: SimulationMode)
    fun onDismissMessage()
}
```
