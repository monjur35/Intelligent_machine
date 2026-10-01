package com.monjur.employeeattendance

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import com.monjur.employeeattendance.presentation.attendance.AttendanceScreen
import com.monjur.employeeattendance.presentation.attendance.AttendanceViewModel
import com.monjur.employeeattendance.ui.theme.EmployeeAttendanceTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val attendanceViewModel: AttendanceViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            EmployeeAttendanceTheme {
                AttendanceScreen(
                    viewModel = attendanceViewModel,
                    modifier = Modifier.fillMaxSize()
                )
            }
        }
    }
}