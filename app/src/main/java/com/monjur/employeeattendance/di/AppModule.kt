package com.monjur.employeeattendance.di

import android.content.Context
import com.monjur.employeeattendance.data.local.AttendanceLocalDataSource
import com.monjur.employeeattendance.data.local.OfficePreferencesDataSource
import com.monjur.employeeattendance.data.location.DefaultLocationClient
import com.monjur.employeeattendance.data.location.LocationClient
import com.monjur.employeeattendance.data.repository.AttendanceRepositoryImpl
import com.monjur.employeeattendance.data.repository.LocationRepositoryImpl
import com.monjur.employeeattendance.domain.repository.AttendanceRepository
import com.monjur.employeeattendance.domain.repository.LocationRepository
import com.monjur.employeeattendance.domain.usecase.CalculateDistanceUseCase
import com.monjur.employeeattendance.domain.usecase.GetOfficeLocationUseCase
import com.monjur.employeeattendance.domain.usecase.MarkAttendanceUseCase
import com.monjur.employeeattendance.domain.usecase.ObserveCurrentLocationUseCase
import com.monjur.employeeattendance.domain.usecase.SaveOfficeLocationUseCase
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideOfficePreferencesDataSource(
        @ApplicationContext context: Context
    ): OfficePreferencesDataSource {
        return OfficePreferencesDataSource(context)
    }

    @Provides
    @Singleton
    fun provideAttendanceLocalDataSource(
        @ApplicationContext context: Context
    ): AttendanceLocalDataSource {
        return AttendanceLocalDataSource(context)
    }

    @Provides
    @Singleton
    fun provideLocationClient(
        @ApplicationContext context: Context
    ): LocationClient {
        return DefaultLocationClient(context)
    }

    @Provides
    @Singleton
    fun provideLocationRepository(
        locationClient: LocationClient
    ): LocationRepository {
        return LocationRepositoryImpl(locationClient)
    }

    @Provides
    @Singleton
    fun provideAttendanceRepository(
        officePreferencesDataSource: OfficePreferencesDataSource,
        attendanceLocalDataSource: AttendanceLocalDataSource
    ): AttendanceRepository {
        return AttendanceRepositoryImpl(officePreferencesDataSource, attendanceLocalDataSource)
    }

    @Provides
    @Singleton
    fun provideSaveOfficeLocationUseCase(
        attendanceRepository: AttendanceRepository
    ): SaveOfficeLocationUseCase {
        return SaveOfficeLocationUseCase(attendanceRepository)
    }

    @Provides
    @Singleton
    fun provideGetOfficeLocationUseCase(
        attendanceRepository: AttendanceRepository
    ): GetOfficeLocationUseCase {
        return GetOfficeLocationUseCase(attendanceRepository)
    }

    @Provides
    @Singleton
    fun provideObserveCurrentLocationUseCase(
        locationRepository: LocationRepository
    ): ObserveCurrentLocationUseCase {
        return ObserveCurrentLocationUseCase(locationRepository)
    }

    @Provides
    @Singleton
    fun provideCalculateDistanceUseCase(
        locationRepository: LocationRepository
    ): CalculateDistanceUseCase {
        return CalculateDistanceUseCase(locationRepository)
    }

    @Provides
    @Singleton
    fun provideMarkAttendanceUseCase(
        attendanceRepository: AttendanceRepository,
        calculateDistanceUseCase: CalculateDistanceUseCase
    ): MarkAttendanceUseCase {
        return MarkAttendanceUseCase(attendanceRepository, calculateDistanceUseCase)
    }

    @Provides
    @Singleton
    fun provideGetAttendanceHistoryUseCase(
        attendanceRepository: AttendanceRepository
    ): com.monjur.employeeattendance.domain.usecase.GetAttendanceHistoryUseCase {
        return com.monjur.employeeattendance.domain.usecase.GetAttendanceHistoryUseCase(attendanceRepository)
    }
}
