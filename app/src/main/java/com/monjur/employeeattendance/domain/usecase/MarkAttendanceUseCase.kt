package com.monjur.employeeattendance.domain.usecase

import com.monjur.employeeattendance.domain.model.AttendanceRecord
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import java.util.UUID

class MarkAttendanceUseCase(
    private val attendanceRepository: AttendanceRepository,
    private val calculateDistanceUseCase: CalculateDistanceUseCase
) {
    suspend operator fun invoke(
        currentLat: Double,
        currentLng: Double,
        officeLat: Double,
        officeLng: Double,
        isSimulated: Boolean = false
    ): Result<AttendanceRecord> {
        val distance = calculateDistanceUseCase(
            currentLat = currentLat,
            currentLng = currentLng,
            officeLat = officeLat,
            officeLng = officeLng
        )

        return if (calculateDistanceUseCase.isWithinGeofence(distance, 50.0f)) {
            val record = AttendanceRecord(
                id = UUID.randomUUID().toString(),
                timestamp = System.currentTimeMillis(),
                latitude = currentLat,
                longitude = currentLng,
                distanceMeters = distance,
                isSuccess = true,
                isSimulated = isSimulated
            )
            attendanceRepository.recordAttendance(record)
            Result.success(record)
        } else {
            Result.failure(
                IllegalStateException(
                    "Out of range: You must be within 50 meters of the office. Current distance: ${distance.toInt()}m"
                )
            )
        }
    }
}
