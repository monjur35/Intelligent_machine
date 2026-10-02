package com.monjur.employeeattendance.data.location

import com.monjur.employeeattendance.domain.model.LocationCoordinates
import kotlinx.coroutines.flow.Flow

interface LocationClient {
    fun getLocationUpdates(intervalMs: Long = 3000L): Flow<LocationCoordinates>
    suspend fun getCurrentLocation(): LocationCoordinates?
    fun observeGpsStatus(): Flow<Boolean>
    fun isGpsEnabled(): Boolean

    class LocationException(message: String, cause: Throwable? = null) : Exception(message, cause)
}
