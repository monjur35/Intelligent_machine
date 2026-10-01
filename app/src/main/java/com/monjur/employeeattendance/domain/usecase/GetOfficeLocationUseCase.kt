package com.monjur.employeeattendance.domain.usecase

import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import kotlinx.coroutines.flow.Flow

class GetOfficeLocationUseCase(
    private val attendanceRepository: AttendanceRepository
) {
    operator fun invoke(): Flow<OfficeLocation?> {
        return attendanceRepository.getOfficeLocation()
    }
}
