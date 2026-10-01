package com.monjur.employeeattendance.domain.usecase

import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.repository.LocationRepository
import kotlinx.coroutines.flow.Flow

class ObserveCurrentLocationUseCase(
    private val locationRepository: LocationRepository
) {
    operator fun invoke(): Flow<LocationCoordinates> {
        return locationRepository.observeCurrentLocation()
    }

    suspend fun getCurrentLocation(): LocationCoordinates? {
        return locationRepository.getCurrentLocation()
    }
}
