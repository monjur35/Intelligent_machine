package com.monjur.employeeattendance.data.location

import android.Manifest
import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Looper
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import com.monjur.employeeattendance.domain.model.LocationCoordinates
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.resume

class DefaultLocationClient(
    private val context: Context,
    private val client: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
) : LocationClient {

    private fun hasLocationPermission(): Boolean {
        val fineLocationGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        val coarseLocationGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        return fineLocationGranted || coarseLocationGranted
    }

    override fun isGpsEnabled(): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return false
        return LocationManagerCompat.isLocationEnabled(locationManager) ||
                locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    override fun observeGpsStatus(): Flow<Boolean> = callbackFlow {
        // Emit initial status
        trySend(isGpsEnabled())

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                if (intent?.action == LocationManager.PROVIDERS_CHANGED_ACTION) {
                    trySend(isGpsEnabled())
                }
            }
        }

        val filter = IntentFilter(LocationManager.PROVIDERS_CHANGED_ACTION)
        try {
            context.registerReceiver(receiver, filter)
        } catch (e: Exception) {
            // Ignore register errors if any
        }

        awaitClose {
            try {
                context.unregisterReceiver(receiver)
            } catch (e: Exception) {
                // Ignore unregister errors
            }
        }
    }.distinctUntilChanged()

    @SuppressLint("MissingPermission")
    override fun getLocationUpdates(intervalMs: Long): Flow<LocationCoordinates> = callbackFlow {
        if (!hasLocationPermission()) {
            close(LocationClient.LocationException("Location permissions are not granted."))
            return@callbackFlow
        }

        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMs)
            .setMinUpdateIntervalMillis(intervalMs / 2)
            .setMinUpdateDistanceMeters(1.0f)
            .build()

        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                super.onLocationResult(result)
                result.lastLocation?.let { location ->
                    trySend(
                        LocationCoordinates(
                            latitude = location.latitude,
                            longitude = location.longitude,
                            accuracyMeters = location.accuracy,
                            timestamp = location.time
                        )
                    )
                }
            }
        }

        try {
            client.requestLocationUpdates(
                request,
                locationCallback,
                Looper.getMainLooper()
            )
        } catch (e: SecurityException) {
            close(LocationClient.LocationException("Security exception requesting location updates", e))
        } catch (e: Exception) {
            close(LocationClient.LocationException("Failed to request location updates", e))
        }

        awaitClose {
            client.removeLocationUpdates(locationCallback)
        }
    }

    @SuppressLint("MissingPermission")
    override suspend fun getCurrentLocation(): LocationCoordinates? {
        if (!hasLocationPermission() || !isGpsEnabled()) return null

        val cancellationTokenSource = CancellationTokenSource()

        // 1. First attempt: client.getCurrentLocation with high accuracy and cancellation token
        val freshLocation = try {
            withTimeoutOrNull(4000L) {
                suspendCancellableCoroutine<Location?> { continuation ->
                    client.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, cancellationTokenSource.token)
                        .addOnSuccessListener { location: Location? ->
                            if (continuation.isActive) {
                                continuation.resume(location)
                            }
                        }
                        .addOnFailureListener {
                            if (continuation.isActive) {
                                continuation.resume(null)
                            }
                        }
                        .addOnCanceledListener {
                            if (continuation.isActive) {
                                continuation.resume(null)
                            }
                        }
                    continuation.invokeOnCancellation {
                        cancellationTokenSource.cancel()
                    }
                }
            }
        } catch (e: Exception) {
            null
        }

        if (freshLocation != null) {
            return LocationCoordinates(
                latitude = freshLocation.latitude,
                longitude = freshLocation.longitude,
                accuracyMeters = freshLocation.accuracy,
                timestamp = freshLocation.time
            )
        }

        // 2. Second attempt: Check lastLocation if available
        val lastLoc = try {
            suspendCancellableCoroutine<Location?> { continuation ->
                client.lastLocation
                    .addOnSuccessListener { lastLocation: Location? ->
                        if (continuation.isActive) {
                            continuation.resume(lastLocation)
                        }
                    }
                    .addOnFailureListener {
                        if (continuation.isActive) {
                            continuation.resume(null)
                        }
                    }
            }
        } catch (e: Exception) {
            null
        }

        if (lastLoc != null) {
            return LocationCoordinates(
                latitude = lastLoc.latitude,
                longitude = lastLoc.longitude,
                accuracyMeters = lastLoc.accuracy,
                timestamp = lastLoc.time
            )
        }

        // 3. Third attempt: Active location request with high accuracy (especially useful if GPS was just enabled)
        return try {
            withTimeoutOrNull(6000L) {
                suspendCancellableCoroutine<LocationCoordinates?> { continuation ->
                    val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 1000L)
                        .setMaxUpdates(1)
                        .setMinUpdateDistanceMeters(0f)
                        .build()

                    val callback = object : LocationCallback() {
                        override fun onLocationResult(result: LocationResult) {
                            val loc = result.lastLocation
                            client.removeLocationUpdates(this)
                            if (continuation.isActive) {
                                continuation.resume(
                                    loc?.let {
                                        LocationCoordinates(
                                            latitude = it.latitude,
                                            longitude = it.longitude,
                                            accuracyMeters = it.accuracy,
                                            timestamp = it.time
                                        )
                                    }
                                )
                            }
                        }
                    }

                    client.requestLocationUpdates(request, callback, Looper.getMainLooper())

                    continuation.invokeOnCancellation {
                        client.removeLocationUpdates(callback)
                    }
                }
            }
        } catch (e: Exception) {
            null
        }
    }
}
