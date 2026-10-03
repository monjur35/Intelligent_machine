package com.monjur.employeeattendance.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun AttendanceActionCard(
    isWithinGeofence: Boolean,
    isAttendanceMarked: Boolean,
    isLoading: Boolean,
    onMarkAttendanceClick: () -> Unit,
    modifier: Modifier = Modifier,
    attendanceTimestamp: Long? = null,
    hasLocationPermission: Boolean = true,
    isLiveGps: Boolean = true,
    availabilityWindow: String = "AVAILABLE 09:00 AM - 10:30 AM"
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            val isPermissionRequired = isLiveGps && !hasLocationPermission
            val punchInTime = remember(attendanceTimestamp) {
                if (attendanceTimestamp != null && attendanceTimestamp > 0L) {
                    SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date(attendanceTimestamp))
                } else null
            }

            // Lock / Success Icon in circular background
            val iconBgColor by animateColorAsState(
                targetValue = when {
                    isAttendanceMarked -> Color(0xFFDCFCE7) // Light Green
                    isPermissionRequired -> Color(0xFFFEF3C7) // Light Amber
                    isWithinGeofence -> Color(0xFFDBEAFE) // Light Blue
                    else -> Color(0xFFF1F5F9) // Light Slate
                },
                label = "icon_bg"
            )

            val iconColor by animateColorAsState(
                targetValue = when {
                    isAttendanceMarked -> Color(0xFF16A34A)
                    isPermissionRequired -> Color(0xFFD97706) // Amber
                    isWithinGeofence -> Color(0xFF2563EB)
                    else -> Color(0xFF94A3B8)
                },
                label = "icon_tint"
            )

            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(iconBgColor),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = if (isAttendanceMarked) Icons.Default.CheckCircle else Icons.Default.Lock,
                    contentDescription = null,
                    tint = iconColor,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Action Pill Button
            val isButtonEnabled = (isWithinGeofence || isPermissionRequired) && !isLoading && !isAttendanceMarked

            Button(
                onClick = onMarkAttendanceClick,
                enabled = isButtonEnabled,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(26.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFF2563EB),
                    contentColor = Color.White,
                    disabledContainerColor = Color(0xFFE2E8F0),
                    disabledContentColor = Color(0xFF94A3B8)
                )
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        color = Color.White,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text(
                        text = when {
                            isAttendanceMarked -> "Attendance Recorded"
                            isPermissionRequired -> "Grant Location Permission"
                            isWithinGeofence -> "Mark Attendance"
                            else -> "Mark Attendance"
                        },
                        fontSize = 15.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Availability footer
            Text(
                text = when {
                    isPermissionRequired -> "LOCATION PERMISSION NEEDED"
                    isAttendanceMarked && punchInTime != null -> "PUNCH IN RECORDED AT $punchInTime"
                    else -> availabilityWindow
                },
                fontSize = 11.sp,
                fontWeight = FontWeight.Medium,
                color = if (isPermissionRequired) Color(0xFFD97706) else Color(0xFF94A3B8),
                letterSpacing = 0.8.sp
            )
        }
    }
}
