package com.monjur.employeeattendance.presentation.attendance

import android.Manifest
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.content.PermissionChecker
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.monjur.employeeattendance.domain.model.SimulationMode
import com.monjur.employeeattendance.presentation.components.AttendanceActionCard
import com.monjur.employeeattendance.presentation.components.AttendanceTopBar
import com.monjur.employeeattendance.presentation.components.DistanceMeterGauge
import com.monjur.employeeattendance.presentation.components.OfficeContextCard
import com.monjur.employeeattendance.presentation.components.SimulationControlCard

@Composable
fun AttendanceScreen(
    viewModel: AttendanceViewModel,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val snackbarHostState = remember { SnackbarHostState() }
    var showPermissionRationale by remember { mutableStateOf(false) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val fineGranted = permissions[Manifest.permission.ACCESS_FINE_LOCATION] == true
        val coarseGranted = permissions[Manifest.permission.ACCESS_COARSE_LOCATION] == true
        val isGranted = fineGranted || coarseGranted
        viewModel.onPermissionResult(isGranted)
        if (!isGranted) {
            showPermissionRationale = true
        }
    }

    // Lifecycle-aware permission check & location observation
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_RESUME -> {
                    val hasPermission = checkLocationPermission(context)
                    viewModel.onPermissionResult(hasPermission)
                    viewModel.checkGpsStatus()
                }
                Lifecycle.Event.ON_PAUSE, Lifecycle.Event.ON_STOP -> {
                    viewModel.stopObservingLocation()
                }
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            viewModel.stopObservingLocation()
        }
    }

    // Initial permission request
    LaunchedEffect(Unit) {
        if (!checkLocationPermission(context)) {
            permissionLauncher.launch(
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        }
    }

    // Handle snackbar messages for errors and successes
    LaunchedEffect(uiState.errorMessage, uiState.successMessage) {
        uiState.errorMessage?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.onDismissMessage()
        }
        uiState.successMessage?.let { success ->
            snackbarHostState.showSnackbar(success)
            viewModel.onDismissMessage()
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            AttendanceTopBar(title = "Attendance")
        },
        containerColor = Color(0xFFF8FAFC)
    ) { innerPadding ->
        Column(
            modifier = modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 4.dp)
                .navigationBarsPadding() // Ensures no overlap with device navigation bar
        ) {
            // STEP 1: Office Context Card
            OfficeContextCard(
                officeLocation = uiState.officeLocation,
                onSetLocationClick = {
                    if (!checkLocationPermission(context)) {
                        permissionLauncher.launch(
                            arrayOf(
                                Manifest.permission.ACCESS_FINE_LOCATION,
                                Manifest.permission.ACCESS_COARSE_LOCATION
                            )
                        )
                    } else {
                        viewModel.onSetOfficeLocationClicked()
                    }
                },
                isLoading = uiState.isLoading,
                isGpsEnabled = uiState.isGpsEnabled
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Real-Time Distance Meter Radial Gauge
            DistanceMeterGauge(
                distanceMeters = uiState.distanceToOfficeMeters,
                isWithinGeofence = uiState.isWithinGeofence,
                officeLocationSet = uiState.officeLocation != null
            )

            Spacer(modifier = Modifier.height(24.dp))

            // Attendance Action (Lock / Check-in) Card
            AttendanceActionCard(
                isWithinGeofence = uiState.isWithinGeofence,
                isAttendanceMarked = uiState.isAttendanceMarked,
                isLoading = uiState.isLoading,
                hasLocationPermission = uiState.hasLocationPermission,
                isLiveGps = uiState.simulationMode == SimulationMode.REAL_GPS,
                onMarkAttendanceClick = {
                    if (uiState.simulationMode == SimulationMode.REAL_GPS && (!uiState.hasLocationPermission || !checkLocationPermission(context))) {
                        showPermissionRationale = true
                    } else {
                        viewModel.onMarkAttendanceClicked()
                    }
                }
            )

            Spacer(modifier = Modifier.height(20.dp))

            // Testing / Evaluation Simulation Mode Bar (Gated to DEBUG builds to protect production geofence)
            if (com.monjur.employeeattendance.BuildConfig.DEBUG) {
                SimulationControlCard(
                    currentMode = uiState.simulationMode,
                    onModeSelect = { mode ->
                        viewModel.onSimulationModeChanged(mode)
                    }
                )
                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }

    // Permission Rationale Dialog
    if (showPermissionRationale) {
        AlertDialog(
            onDismissRequest = { showPermissionRationale = false },
            title = { Text(text = "Location Permission Required") },
            text = {
                Text(
                    text = "Geo-Fenced attendance verification requires location permission to calculate your real-time distance from the office.",
                    fontSize = 14.sp
                )
            },
            confirmButton = {
                Button(
                    onClick = {
                        showPermissionRationale = false
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.fromParts("package", context.packageName, null)
                        }
                        context.startActivity(intent)
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF2563EB))
                ) {
                    Text("Open Settings")
                }
            },
            dismissButton = {
                OutlinedButton(onClick = { showPermissionRationale = false }) {
                    Text("Dismiss")
                }
            }
        )
    }
}

private fun checkLocationPermission(context: Context): Boolean {
    val fineGranted = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.ACCESS_FINE_LOCATION
    ) == PermissionChecker.PERMISSION_GRANTED

    val coarseGranted = ContextCompat.checkSelfPermission(
        context,
        Manifest.permission.ACCESS_COARSE_LOCATION
    ) == PermissionChecker.PERMISSION_GRANTED

    return fineGranted || coarseGranted
}
