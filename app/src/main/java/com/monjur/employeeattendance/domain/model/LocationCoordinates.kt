package com.monjur.employeeattendance.domain.model

data class LocationCoordinates(
    val latitude: Double,
    val longitude: Double,
    val accuracyMeters: Float = 0f,
    val timestamp: Long = System.currentTimeMillis()
)
