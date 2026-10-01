package com.monjur.employeeattendance.domain.usecase

import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.repository.AttendanceRepository

class SaveOfficeLocationUseCase(
    private val attendanceRepository: AttendanceRepository
) {
    suspend operator fun invoke(officeLocation: OfficeLocation) {
        attendanceRepository.saveOfficeLocation(officeLocation)
    }
}
