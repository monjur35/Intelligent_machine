package com.monjur.employeeattendance

import com.monjur.employeeattendance.data.repository.LocationRepositoryImpl
import com.monjur.employeeattendance.domain.model.AttendanceRecord
import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import com.monjur.employeeattendance.domain.repository.LocationRepository
import com.monjur.employeeattendance.domain.usecase.CalculateDistanceUseCase
import com.monjur.employeeattendance.domain.usecase.MarkAttendanceUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class MarkAttendanceUseCaseTest {

    private lateinit var markAttendanceUseCase: MarkAttendanceUseCase
    private val recordedList = mutableListOf<AttendanceRecord>()

    private val fakeLocationRepository = object : LocationRepository {
        override fun observeCurrentLocation(): Flow<LocationCoordinates> = emptyFlow()
        override suspend fun getCurrentLocation(): LocationCoordinates? = null

        override fun calculateDistanceMeters(
            startLat: Double,
            startLng: Double,
            endLat: Double,
            endLng: Double
        ): Float {
            return LocationRepositoryImpl.haversineMeters(startLat, startLng, endLat, endLng)
        }
    }

    private val fakeAttendanceRepository = object : AttendanceRepository {
        override fun getOfficeLocation(): Flow<OfficeLocation?> = emptyFlow()
        override suspend fun saveOfficeLocation(location: OfficeLocation) {}

        override suspend fun recordAttendance(record: AttendanceRecord) {
            recordedList.add(record)
        }

        override fun getAttendanceHistory(): Flow<List<AttendanceRecord>> = emptyFlow()
    }

    @Before
    fun setUp() {
        recordedList.clear()
        val calcUseCase = CalculateDistanceUseCase(fakeLocationRepository)
        markAttendanceUseCase = MarkAttendanceUseCase(fakeAttendanceRepository, calcUseCase)
    }

    @Test
    fun `markAttendance succeeds when location is within 50 meters`() = runBlocking {
        // Point is ~20 meters away
        val officeLat = 40.712800
        val officeLng = -74.006000
        val currentLat = 40.712980 // approx 20m north
        val currentLng = -74.006000

        val result = markAttendanceUseCase(
            currentLat = currentLat,
            currentLng = currentLng,
            officeLat = officeLat,
            officeLng = officeLng
        )

        assertTrue(result.isSuccess)
        val record = result.getOrNull()
        assertTrue(record != null)
        assertTrue(record!!.isSuccess)
        assertTrue(record.distanceMeters <= 50.0f)
        assertEquals(1, recordedList.size)
    }

    @Test
    fun `markAttendance fails when location exceeds 50 meters`() = runBlocking {
        // Point is ~111 meters away
        val officeLat = 40.7128
        val officeLng = -74.0060
        val currentLat = 40.7138
        val currentLng = -74.0060

        val result = markAttendanceUseCase(
            currentLat = currentLat,
            currentLng = currentLng,
            officeLat = officeLat,
            officeLng = officeLng
        )

        assertTrue(result.isFailure)
        assertEquals(0, recordedList.size)
        val message = result.exceptionOrNull()?.message
        assertTrue(message?.contains("Out of range") == true)
    }
}
