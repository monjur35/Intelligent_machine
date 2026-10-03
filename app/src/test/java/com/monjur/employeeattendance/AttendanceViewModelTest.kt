package com.monjur.employeeattendance

import com.monjur.employeeattendance.domain.model.AttendanceRecord
import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.model.SimulationMode
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import com.monjur.employeeattendance.domain.repository.LocationRepository
import com.monjur.employeeattendance.domain.usecase.CalculateDistanceUseCase
import com.monjur.employeeattendance.domain.usecase.GetAttendanceHistoryUseCase
import com.monjur.employeeattendance.domain.usecase.GetOfficeLocationUseCase
import com.monjur.employeeattendance.domain.usecase.MarkAttendanceUseCase
import com.monjur.employeeattendance.domain.usecase.ObserveCurrentLocationUseCase
import com.monjur.employeeattendance.domain.usecase.SaveOfficeLocationUseCase
import com.monjur.employeeattendance.presentation.attendance.AttendanceViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AttendanceViewModelTest {

    private val testDispatcher = StandardTestDispatcher()

    private val officeFlow = MutableStateFlow<OfficeLocation?>(null)
    private val historyFlow = MutableStateFlow<List<AttendanceRecord>>(emptyList())
    private val locationFlow = MutableStateFlow(LocationCoordinates(40.7128, -74.0060, 5f, System.currentTimeMillis()))
    private val gpsFlow = MutableStateFlow(true)

    private val fakeAttendanceRepository = object : AttendanceRepository {
        override fun getOfficeLocation(): Flow<OfficeLocation?> = officeFlow
        override suspend fun saveOfficeLocation(location: OfficeLocation) {
            officeFlow.value = location
        }
        override suspend fun recordAttendance(record: AttendanceRecord) {
            historyFlow.value = listOf(record) + historyFlow.value
        }
        override fun getAttendanceHistory(): Flow<List<AttendanceRecord>> = historyFlow
    }

    private val fakeLocationRepository = object : LocationRepository {
        override fun observeCurrentLocation(): Flow<LocationCoordinates> = locationFlow
        override suspend fun getCurrentLocation(): LocationCoordinates? = locationFlow.value
        override fun calculateDistanceMeters(
            startLat: Double,
            startLng: Double,
            endLat: Double,
            endLng: Double
        ): Float = 20.0f
    }

    private lateinit var viewModel: AttendanceViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        val saveOffice = SaveOfficeLocationUseCase(fakeAttendanceRepository)
        val getOffice = GetOfficeLocationUseCase(fakeAttendanceRepository)
        val observeLocation = ObserveCurrentLocationUseCase(fakeLocationRepository)
        val calculateDistance = CalculateDistanceUseCase(fakeLocationRepository)
        val markAttendance = MarkAttendanceUseCase(fakeAttendanceRepository, calculateDistance)
        val getHistory = GetAttendanceHistoryUseCase(fakeAttendanceRepository)

        viewModel = AttendanceViewModel(
            saveOfficeLocationUseCase = saveOffice,
            getOfficeLocationUseCase = getOffice,
            observeCurrentLocationUseCase = observeLocation,
            calculateDistanceUseCase = calculateDistance,
            markAttendanceUseCase = markAttendance,
            getAttendanceHistoryUseCase = getHistory
        )
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state observes saved office location and gps`() = runTest(testDispatcher) {
        val testOffice = OfficeLocation(40.7128, -74.0060, "Main Headquarters", System.currentTimeMillis())
        officeFlow.value = testOffice

        advanceUntilIdle()

        assertEquals(testOffice, viewModel.uiState.value.officeLocation)
        assertTrue(viewModel.uiState.value.isGpsEnabled)
    }

    @Test
    fun `simulation mode switches geofence range calculations dynamically`() = runTest(testDispatcher) {
        val testOffice = OfficeLocation(40.7128, -74.0060, "HQ", System.currentTimeMillis())
        officeFlow.value = testOffice
        advanceUntilIdle()

        viewModel.onSimulationModeChanged(SimulationMode.SIMULATE_IN_RANGE)
        assertTrue(viewModel.uiState.value.isWithinGeofence)
        assertEquals(24.5f, viewModel.uiState.value.distanceToOfficeMeters)

        viewModel.onSimulationModeChanged(SimulationMode.SIMULATE_OUT_OF_RANGE)
        assertFalse(viewModel.uiState.value.isWithinGeofence)
        assertEquals(120.0f, viewModel.uiState.value.distanceToOfficeMeters)
    }

    @Test
    fun `mark attendance marks status and prevents duplicate check-in today`() = runTest(testDispatcher) {
        val testOffice = OfficeLocation(40.7128, -74.0060, "HQ", System.currentTimeMillis())
        officeFlow.value = testOffice
        viewModel.onSimulationModeChanged(SimulationMode.SIMULATE_IN_RANGE)
        advanceUntilIdle()

        viewModel.onMarkAttendanceClicked()
        advanceUntilIdle()

        assertTrue(viewModel.uiState.value.isAttendanceMarked)
        assertNotNull(viewModel.uiState.value.attendanceTimestamp)
        assertTrue(viewModel.uiState.value.successMessage?.contains("successfully") == true)

        // Attempt second check-in today
        viewModel.onMarkAttendanceClicked()
        advanceUntilIdle()

        assertTrue(viewModel.uiState.value.errorMessage?.contains("already") == true)
    }
}
