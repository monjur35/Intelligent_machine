package com.monjur.employeeattendance.presentation.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.min

@Composable
fun DistanceMeterGauge(
    distanceMeters: Float?,
    isWithinGeofence: Boolean,
    officeLocationSet: Boolean,
    modifier: Modifier = Modifier
) {
    val activeColor by animateColorAsState(
        targetValue = when {
            !officeLocationSet -> Color(0xFF94A3B8)
            isWithinGeofence -> Color(0xFF10B981) // Emerald Green
            else -> Color(0xFFEF4444) // Coral Red
        },
        animationSpec = tween(durationMillis = 400),
        label = "gauge_color"
    )

    // Calculate progress fraction for the circular arc
    val rawDistance = distanceMeters ?: 120f
    val clampedDistance = min(rawDistance, 250f)
    val targetSweep = if (isWithinGeofence) {
        0.85f
    } else {
        // Proportion of distance from 50m to 250m
        0.35f + (clampedDistance / 250f) * 0.5f
    }

    val animatedSweepFraction by animateFloatAsState(
        targetValue = targetSweep.coerceIn(0.1f, 1f),
        animationSpec = tween(durationMillis = 600, easing = FastOutSlowInEasing),
        label = "sweep_progress"
    )

    Column(
        modifier = modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Radial Circular Gauge
        Box(
            modifier = Modifier.size(150.dp),
            contentAlignment = Alignment.Center
        ) {
            Canvas(modifier = Modifier.size(130.dp)) {
                val strokeWidth = 8.dp.toPx()
                val diameter = size.minDimension - strokeWidth
                val topLeft = androidx.compose.ui.geometry.Offset(strokeWidth / 2, strokeWidth / 2)
                val arcSize = androidx.compose.ui.geometry.Size(diameter, diameter)

                // Background track arc
                drawArc(
                    color = Color(0xFFF1F5F9),
                    startAngle = 135f,
                    sweepAngle = 270f,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )

                // Foreground active arc
                drawArc(
                    color = activeColor,
                    startAngle = 135f,
                    sweepAngle = 270f * animatedSweepFraction,
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }

            // Inner Distance Display
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                val displayDistance = when {
                    !officeLocationSet -> "--"
                    distanceMeters != null -> "${distanceMeters.toInt()}m"
                    else -> "120m"
                }

                Text(
                    text = displayDistance,
                    fontSize = 28.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF1E293B)
                )
                Text(
                    text = if (isWithinGeofence) "IN RANGE" else "AWAY",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFF94A3B8),
                    letterSpacing = 1.sp
                )
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Status Badge Dot
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(activeColor)
            )
            Spacer(modifier = Modifier.size(6.dp))
            Text(
                text = when {
                    !officeLocationSet -> "OFFICE NOT CONFIGURED"
                    isWithinGeofence -> "IN RANGE"
                    else -> "OUT OF RANGE"
                },
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                color = activeColor,
                letterSpacing = 0.8.sp
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Subtitle guidance
        Text(
            text = when {
                !officeLocationSet -> "Please set your office location above to enable check-in."
                isWithinGeofence -> "You are within 50 meters of the office. Check-in is available."
                else -> "Move within 50 meters of the designated office location to enable check-in."
            },
            fontSize = 12.sp,
            color = Color(0xFF64748B),
            textAlign = TextAlign.Center,
            lineHeight = 16.sp,
            modifier = Modifier.padding(horizontal = 24.dp)
        )
    }
}
