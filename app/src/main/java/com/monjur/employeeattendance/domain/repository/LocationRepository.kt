package com.monjur.employeeattendance.domain.repository

import com.monjur.employeeattendance.domain.model.LocationCoordinates
import kotlinx.coroutines.flow.Flow

interface LocationRepository {
    fun observeCurrentLocation(): Flow<LocationCoordinates>
    suspend fun getCurrentLocation(): LocationCoordinates?
    fun calculateDistanceMeters(
        startLat: Double,
        startLng: Double,
        endLat: Double,
        endLng: Double
    ): Float
}
