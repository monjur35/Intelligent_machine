package com.monjur.employeeattendance.data.repository

import android.location.Location
import com.monjur.employeeattendance.data.location.LocationClient
import com.monjur.employeeattendance.domain.model.LocationCoordinates
import com.monjur.employeeattendance.domain.repository.LocationRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

class LocationRepositoryImpl(
    private val locationClient: LocationClient
) : LocationRepository {

    override fun observeCurrentLocation(): Flow<LocationCoordinates> {
        return locationClient.getLocationUpdates(intervalMs = 2500L)
            .catch { emit(LocationCoordinates(0.0, 0.0, 0f, 0L)) }
    }

    override suspend fun getCurrentLocation(): LocationCoordinates? {
        return locationClient.getCurrentLocation()
    }

    override fun calculateDistanceMeters(
        startLat: Double,
        startLng: Double,
        endLat: Double,
        endLng: Double
    ): Float {
        return try {
            val results = FloatArray(1)
            Location.distanceBetween(startLat, startLng, endLat, endLng, results)
            results[0]
        } catch (e: Exception) {
            // Pure Kotlin Haversine fallback (e.g. in JVM Unit tests or when Location framework is not mocked)
            haversineMeters(startLat, startLng, endLat, endLng)
        }
    }

    companion object {
        fun haversineMeters(
            lat1: Double,
            lon1: Double,
            lat2: Double,
            lon2: Double
        ): Float {
            val earthRadius = 6371000.0 // meters
            val dLat = Math.toRadians(lat2 - lat1)
            val dLon = Math.toRadians(lon2 - lon1)
            val a = sin(dLat / 2) * sin(dLat / 2) +
                    cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                    sin(dLon / 2) * sin(dLon / 2)
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return (earthRadius * c).toFloat()
        }
    }
}
