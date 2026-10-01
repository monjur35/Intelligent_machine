package com.monjur.employeeattendance.presentation.attendance

import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.model.SimulationMode

data class AttendanceUiState(
    val isLoading: Boolean = false,
    val hasLocationPermission: Boolean = false,
    val isGpsEnabled: Boolean = true,
    val officeLocation: OfficeLocation? = null,
    val currentLocation: LocationCoordinates? = null,
    val distanceToOfficeMeters: Float? = null,
    val isWithinGeofence: Boolean = false,
    val isAttendanceMarked: Boolean = false,
    val attendanceTimestamp: Long? = null,
    val simulationMode: SimulationMode = SimulationMode.REAL_GPS,
    val errorMessage: String? = null,
    val successMessage: String? = null
)
