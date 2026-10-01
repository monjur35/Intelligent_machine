package com.monjur.employeeattendance.domain.usecase

import com.monjur.employeeattendance.domain.repository.LocationRepository

class CalculateDistanceUseCase(
    private val locationRepository: LocationRepository
) {
    operator fun invoke(
        currentLat: Double,
        currentLng: Double,
        officeLat: Double,
        officeLng: Double
    ): Float {
        return locationRepository.calculateDistanceMeters(
            startLat = currentLat,
            startLng = currentLng,
            endLat = officeLat,
            endLng = officeLng
        )
    }

    fun isWithinGeofence(distanceMeters: Float, radiusMeters: Float = 50.0f): Boolean {
        return distanceMeters <= radiusMeters
    }
}
