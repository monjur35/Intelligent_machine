package com.monjur.employeeattendance.domain.model

data class AttendanceRecord(
    val id: String,
    val timestamp: Long,
    val latitude: Double,
    val longitude: Double,
    val distanceMeters: Float,
    val isSuccess: Boolean,
    val isSimulated: Boolean = false
)
