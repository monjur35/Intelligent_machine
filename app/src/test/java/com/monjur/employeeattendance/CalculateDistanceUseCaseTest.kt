package com.monjur.employeeattendance

import com.monjur.employeeattendance.data.repository.LocationRepositoryImpl
import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.repository.LocationRepository
import com.monjur.employeeattendance.domain.usecase.CalculateDistanceUseCase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CalculateDistanceUseCaseTest {

    private lateinit var calculateDistanceUseCase: CalculateDistanceUseCase

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

    @Before
    fun setUp() {
        calculateDistanceUseCase = CalculateDistanceUseCase(fakeLocationRepository)
    }

    @Test
    fun `isWithinGeofence returns true when distance is less than 50 meters`() {
        assertTrue(calculateDistanceUseCase.isWithinGeofence(0.0f))
        assertTrue(calculateDistanceUseCase.isWithinGeofence(25.0f))
        assertTrue(calculateDistanceUseCase.isWithinGeofence(49.9f))
        assertTrue(calculateDistanceUseCase.isWithinGeofence(50.0f))
    }

    @Test
    fun `isWithinGeofence returns false when distance exceeds 50 meters`() {
        assertFalse(calculateDistanceUseCase.isWithinGeofence(50.1f))
        assertFalse(calculateDistanceUseCase.isWithinGeofence(120.0f))
        assertFalse(calculateDistanceUseCase.isWithinGeofence(500.0f))
    }

    @Test
    fun `distance calculation between identical coordinates is zero`() {
        val distance = calculateDistanceUseCase(
            currentLat = 40.7128,
            currentLng = -74.0060,
            officeLat = 40.7128,
            officeLng = -74.0060
        )
        assertEquals(0.0f, distance, 0.01f)
    }

    @Test
    fun `distance calculation between close points produces accurate meter distance`() {
        // ~111 meters per 0.001 deg latitude
        val distance = calculateDistanceUseCase(
            currentLat = 40.7128,
            currentLng = -74.0060,
            officeLat = 40.7138,
            officeLng = -74.0060
        )
        assertTrue(distance in 110f..112f)
    }
}
