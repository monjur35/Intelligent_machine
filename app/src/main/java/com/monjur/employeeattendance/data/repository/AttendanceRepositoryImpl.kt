package com.monjur.employeeattendance.data.repository

import com.monjur.employeeattendance.data.local.AttendanceLocalDataSource
import com.monjur.employeeattendance.data.local.OfficePreferencesDataSource
import com.monjur.employeeattendance.domain.model.AttendanceRecord
import com.monjur.employeeattendance.domain.model.OfficeLocation
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import kotlinx.coroutines.flow.Flow

class AttendanceRepositoryImpl(
    private val officePreferencesDataSource: OfficePreferencesDataSource,
    private val attendanceLocalDataSource: AttendanceLocalDataSource
) : AttendanceRepository {

    override fun getOfficeLocation(): Flow<OfficeLocation?> {
        return officePreferencesDataSource.officeLocationFlow
    }

    override suspend fun saveOfficeLocation(location: OfficeLocation) {
        officePreferencesDataSource.saveOfficeLocation(location)
    }

    override suspend fun recordAttendance(record: AttendanceRecord) {
        attendanceLocalDataSource.saveRecord(record)
    }

    override fun getAttendanceHistory(): Flow<List<AttendanceRecord>> {
        return attendanceLocalDataSource.attendanceRecordsFlow
    }
}
