package com.monjur.employeeattendance.domain.usecase

import com.monjur.employeeattendance.domain.model.AttendanceRecord
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import kotlinx.coroutines.flow.Flow

class GetAttendanceHistoryUseCase(
    private val attendanceRepository: AttendanceRepository
) {
    operator fun invoke(): Flow<List<AttendanceRecord>> {
        return attendanceRepository.getAttendanceHistory()
    }
}
