package com.monjur.employeeattendance.domain.repository

import com.monjur.employeeattendance.domain.model.AttendanceRecord
import com.monjur.employeeattendance.domain.model.OfficeLocation
import kotlinx.coroutines.flow.Flow

interface AttendanceRepository {
    fun getOfficeLocation(): Flow<OfficeLocation?>
    suspend fun saveOfficeLocation(location: OfficeLocation)
    suspend fun recordAttendance(record: AttendanceRecord)
    fun getAttendanceHistory(): Flow<List<AttendanceRecord>>
}
