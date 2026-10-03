package com.monjur.employeeattendance.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.monjur.employeeattendance.domain.model.OfficeLocation
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import java.io.IOException

val Context.attendanceDataStore: DataStore<Preferences> by preferencesDataStore(name = "attendance_prefs")

class OfficePreferencesDataSource(context: Context) {

    private val appContext = context.applicationContext

    private object PreferencesKeys {
        val KEY_OFFICE_LAT = doublePreferencesKey("office_lat")
        val KEY_OFFICE_LNG = doublePreferencesKey("office_lng")
        val KEY_OFFICE_LABEL = stringPreferencesKey("office_label")
        val KEY_OFFICE_TIMESTAMP = longPreferencesKey("office_timestamp")
    }

    val officeLocationFlow: Flow<OfficeLocation?> = appContext.attendanceDataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }
        .map { preferences ->
            val lat = preferences[PreferencesKeys.KEY_OFFICE_LAT]
            val lng = preferences[PreferencesKeys.KEY_OFFICE_LNG]
            val label = preferences[PreferencesKeys.KEY_OFFICE_LABEL] ?: "Designated Office"
            val timestamp = preferences[PreferencesKeys.KEY_OFFICE_TIMESTAMP] ?: System.currentTimeMillis()

            if (lat != null && lng != null) {
                OfficeLocation(
                    latitude = lat,
                    longitude = lng,
                    label = label,
                    setTimestamp = timestamp
                )
            } else {
                null
            }
        }

    suspend fun saveOfficeLocation(officeLocation: OfficeLocation) {
        appContext.attendanceDataStore.edit { preferences ->
            preferences[PreferencesKeys.KEY_OFFICE_LAT] = officeLocation.latitude
            preferences[PreferencesKeys.KEY_OFFICE_LNG] = officeLocation.longitude
            preferences[PreferencesKeys.KEY_OFFICE_LABEL] = officeLocation.label
            preferences[PreferencesKeys.KEY_OFFICE_TIMESTAMP] = officeLocation.setTimestamp
        }
    }
}
