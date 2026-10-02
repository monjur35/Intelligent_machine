package com.monjur.employeeattendance.presentation.attendance

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.model.SimulationMode
import com.monjur.employeeattendance.domain.usecase.CalculateDistanceUseCase
import com.monjur.employeeattendance.domain.usecase.GetOfficeLocationUseCase
import com.monjur.employeeattendance.domain.usecase.MarkAttendanceUseCase
import com.monjur.employeeattendance.domain.usecase.ObserveCurrentLocationUseCase
import com.monjur.employeeattendance.domain.usecase.SaveOfficeLocationUseCase
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

@HiltViewModel
class AttendanceViewModel @Inject constructor(
    private val saveOfficeLocationUseCase: SaveOfficeLocationUseCase,
    private val getOfficeLocationUseCase: GetOfficeLocationUseCase,
    private val observeCurrentLocationUseCase: ObserveCurrentLocationUseCase,
    private val calculateDistanceUseCase: CalculateDistanceUseCase,
    private val markAttendanceUseCase: MarkAttendanceUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(AttendanceUiState())
    val uiState: StateFlow<AttendanceUiState> = _uiState.asStateFlow()

    private var locationUpdatesJob: Job? = null
    private var gpsStatusJob: Job? = null

    init {
        observeSavedOfficeLocation()
        observeGpsStatus()
    }

    private fun observeSavedOfficeLocation() {
        getOfficeLocationUseCase()
            .onEach { office ->
                _uiState.update { currentState ->
                    currentState.copy(officeLocation = office)
                }
                recalculateDistance()
            }
            .launchIn(viewModelScope)
    }

    private fun observeGpsStatus() {
        gpsStatusJob?.cancel()
        gpsStatusJob = observeCurrentLocationUseCase.observeGpsStatus()
            .onEach { isGpsOn ->
                _uiState.update { currentState ->
                    currentState.copy(
                        isGpsEnabled = isGpsOn,
                        errorMessage = if (!isGpsOn) {
                            "GPS is disabled. Please turn on Location services."
                        } else if (currentState.errorMessage?.contains("GPS", ignoreCase = true) == true) {
                            null
                        } else {
                            currentState.errorMessage
                        }
                    )
                }

                if (isGpsOn) {
                    if (_uiState.value.hasLocationPermission) {
                        startObservingLocation()
                    }
                } else {
                    stopObservingLocation()
                    _uiState.update { it.copy(currentLocation = null) }
                    recalculateDistance()
                }
            }
            .launchIn(viewModelScope)
    }

    fun checkGpsStatus() {
        val isGpsOn = observeCurrentLocationUseCase.isGpsEnabled()
        _uiState.update { currentState ->
            currentState.copy(
                isGpsEnabled = isGpsOn,
                errorMessage = if (!isGpsOn) {
                    "GPS is disabled. Please turn on Location services."
                } else if (currentState.errorMessage?.contains("GPS", ignoreCase = true) == true) {
                    null
                } else {
                    currentState.errorMessage
                }
            )
        }
        if (isGpsOn && _uiState.value.hasLocationPermission) {
            startObservingLocation()
        }
    }

    fun onPermissionResult(isGranted: Boolean) {
        val isGpsOn = observeCurrentLocationUseCase.isGpsEnabled()
        _uiState.update {
            it.copy(
                hasLocationPermission = isGranted,
                isGpsEnabled = isGpsOn
            )
        }
        if (isGranted) {
            if (isGpsOn) {
                startObservingLocation()
            }
        } else {
            stopObservingLocation()
            _uiState.update {
                it.copy(errorMessage = "Location permission is required to detect office geofence.")
            }
        }
    }

    fun startObservingLocation() {
        if (!_uiState.value.hasLocationPermission || !_uiState.value.isGpsEnabled) return

        if (locationUpdatesJob?.isActive == true) return

        locationUpdatesJob = observeCurrentLocationUseCase()
            .onEach { coords ->
                if (coords.latitude != 0.0 || coords.longitude != 0.0) {
                    _uiState.update { currentState ->
                        currentState.copy(
                            currentLocation = coords,
                            isGpsEnabled = true,
                            errorMessage = if (currentState.errorMessage?.contains("GPS", ignoreCase = true) == true) null else currentState.errorMessage
                        )
                    }
                    recalculateDistance()
                }
            }
            .catch { error ->
                _uiState.update {
                    it.copy(
                        isGpsEnabled = false,
                        errorMessage = error.localizedMessage ?: "Unable to read GPS location."
                    )
                }
            }
            .launchIn(viewModelScope)
    }

    private fun stopObservingLocation() {
        locationUpdatesJob?.cancel()
        locationUpdatesJob = null
    }

    fun onSetOfficeLocationClicked() {
        viewModelScope.launch {
            val isGpsOn = observeCurrentLocationUseCase.isGpsEnabled()
            if (!isGpsOn) {
                _uiState.update {
                    it.copy(
                        isGpsEnabled = false,
                        errorMessage = "GPS is disabled. Please enable GPS on your device."
                    )
                }
                return@launch
            }

            _uiState.update { it.copy(isLoading = true, errorMessage = null) }
            try {
                if (locationUpdatesJob?.isActive != true && _uiState.value.hasLocationPermission) {
                    startObservingLocation()
                }

                val current = _uiState.value.currentLocation
                    ?: observeCurrentLocationUseCase.getCurrentLocation()

                if (current != null && (current.latitude != 0.0 || current.longitude != 0.0)) {
                    val newOffice = OfficeLocation(
                        latitude = current.latitude,
                        longitude = current.longitude,
                        label = "Designated Office",
                        setTimestamp = System.currentTimeMillis()
                    )
                    saveOfficeLocationUseCase(newOffice)
                    _uiState.update {
                        it.copy(
                            officeLocation = newOffice,
                            currentLocation = current,
                            isLoading = false,
                            successMessage = "Office coordinates updated successfully!"
                        )
                    }
                    recalculateDistance()
                } else {
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = "Unable to get high-accuracy GPS fix. Please ensure GPS is enabled."
                        )
                    }
                }
            } catch (e: Exception) {
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        errorMessage = "Error setting office location: ${e.message}"
                    )
                }
            }
        }
    }

    fun onMarkAttendanceClicked() {
        viewModelScope.launch {
            val state = _uiState.value
            val office = state.officeLocation

            if (office == null) {
                _uiState.update { it.copy(errorMessage = "Please set your office location first.") }
                return@launch
            }

            // In simulation mode, mock coordinates inside or outside
            val (currentLat, currentLng) = when (state.simulationMode) {
                SimulationMode.REAL_GPS -> {
                    val curr = state.currentLocation
                    if (curr == null) {
                        _uiState.update { it.copy(errorMessage = "Waiting for GPS fix...") }
                        return@launch
                    }
                    curr.latitude to curr.longitude
                }
                SimulationMode.SIMULATE_IN_RANGE -> {
                    // Coordinates ~25m offset
                    office.latitude + 0.000225 to office.longitude
                }
                SimulationMode.SIMULATE_OUT_OF_RANGE -> {
                    // Coordinates ~120m offset
                    office.latitude + 0.00108 to office.longitude
                }
            }

            _uiState.update { it.copy(isLoading = true) }

            val result = markAttendanceUseCase(
                currentLat = currentLat,
                currentLng = currentLng,
                officeLat = office.latitude,
                officeLng = office.longitude
            )

            result.fold(
                onSuccess = { record ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            isAttendanceMarked = true,
                            attendanceTimestamp = record.timestamp,
                            successMessage = "Attendance marked successfully! (${record.distanceMeters.toInt()}m from office)"
                        )
                    }
                },
                onFailure = { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessage = error.message ?: "Failed to mark attendance."
                        )
                    }
                }
            )
        }
    }

    fun onSimulationModeChanged(mode: SimulationMode) {
        _uiState.update { it.copy(simulationMode = mode) }
        recalculateDistance()
    }

    fun onDismissMessage() {
        _uiState.update { it.copy(errorMessage = null, successMessage = null) }
    }

    private fun recalculateDistance() {
        val state = _uiState.value
        val office = state.officeLocation

        if (office == null) {
            _uiState.update {
                it.copy(
                    distanceToOfficeMeters = null,
                    isWithinGeofence = false
                )
            }
            return
        }

        when (state.simulationMode) {
            SimulationMode.REAL_GPS -> {
                val current = state.currentLocation
                if (current != null && (current.latitude != 0.0 || current.longitude != 0.0)) {
                    val dist = calculateDistanceUseCase(
                        currentLat = current.latitude,
                        currentLng = current.longitude,
                        officeLat = office.latitude,
                        officeLng = office.longitude
                    )
                    val inRange = calculateDistanceUseCase.isWithinGeofence(dist, 50.0f)
                    _uiState.update {
                        it.copy(
                            distanceToOfficeMeters = dist,
                            isWithinGeofence = inRange
                        )
                    }
                } else {
                    _uiState.update {
                        it.copy(
                            distanceToOfficeMeters = null,
                            isWithinGeofence = false
                        )
                    }
                }
            }
            SimulationMode.SIMULATE_IN_RANGE -> {
                _uiState.update {
                    it.copy(
                        distanceToOfficeMeters = 24.5f,
                        isWithinGeofence = true
                    )
                }
            }
            SimulationMode.SIMULATE_OUT_OF_RANGE -> {
                _uiState.update {
                    it.copy(
                        distanceToOfficeMeters = 120.0f,
                        isWithinGeofence = false
                    )
                }
            }
        }
    }
}

class AttendanceViewModelFactory(
    private val saveOfficeLocationUseCase: SaveOfficeLocationUseCase,
    private val getOfficeLocationUseCase: GetOfficeLocationUseCase,
    private val observeCurrentLocationUseCase: ObserveCurrentLocationUseCase,
    private val calculateDistanceUseCase: CalculateDistanceUseCase,
    private val markAttendanceUseCase: MarkAttendanceUseCase
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(AttendanceViewModel::class.java)) {
            return AttendanceViewModel(
                saveOfficeLocationUseCase,
                getOfficeLocationUseCase,
                observeCurrentLocationUseCase,
                calculateDistanceUseCase,
                markAttendanceUseCase
            ) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
