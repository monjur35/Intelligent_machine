package com.monjur.employeeattendance.data.local

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.monjur.employeeattendance.domain.model.AttendanceRecord
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class AttendanceLocalDataSource(context: Context) {

    private val appContext = context.applicationContext

    private object PreferencesKeys {
        val KEY_ATTENDANCE_LOGS = stringPreferencesKey("attendance_logs_csv")
    }

    // Stores CSV-like records: id|timestamp|latitude|longitude|distanceMeters|isSuccess|isSimulated
    val attendanceRecordsFlow: Flow<List<AttendanceRecord>> = appContext.attendanceDataStore.data.map { preferences ->
        val raw = preferences[PreferencesKeys.KEY_ATTENDANCE_LOGS] ?: ""
        if (raw.isBlank()) {
            emptyList()
        } else {
            raw.split(";").mapNotNull { entry ->
                val parts = entry.split("|")
                if (parts.size >= 6) {
                    AttendanceRecord(
                        id = parts[0],
                        timestamp = parts[1].toLongOrNull() ?: 0L,
                        latitude = parts[2].toDoubleOrNull() ?: 0.0,
                        longitude = parts[3].toDoubleOrNull() ?: 0.0,
                        distanceMeters = parts[4].toFloatOrNull() ?: 0f,
                        isSuccess = parts[5].toBooleanStrictOrNull() ?: false,
                        isSimulated = if (parts.size >= 7) parts[6].toBooleanStrictOrNull() ?: false else false
                    )
                } else null
            }
        }
    }

    suspend fun saveRecord(record: AttendanceRecord) {
        appContext.attendanceDataStore.edit { preferences ->
            val existing = preferences[PreferencesKeys.KEY_ATTENDANCE_LOGS] ?: ""
            val entry = "${record.id}|${record.timestamp}|${record.latitude}|${record.longitude}|${record.distanceMeters}|${record.isSuccess}|${record.isSimulated}"
            preferences[PreferencesKeys.KEY_ATTENDANCE_LOGS] = if (existing.isEmpty()) entry else "$entry;$existing"
        }
    }
}
