package com.monjur.employeeattendance.presentation.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.monjur.employeeattendance.domain.model.OfficeLocation
import java.util.Locale

@Composable
fun OfficeContextCard(
    officeLocation: OfficeLocation?,
    onSetLocationClick: () -> Unit,
    modifier: Modifier = Modifier,
    isLoading: Boolean = false
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
            // Header: Step 1 with status dot
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "STEP 1: OFFICE CONTEXT",
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFF64748B),
                    letterSpacing = 0.8.sp
                )
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(if (officeLocation != null) Color(0xFF2563EB) else Color(0xFFCBD5E1))
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Map preview container with coordinates chip
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(110.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFFF1F5F9))
                    .border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(14.dp)),
                contentAlignment = Alignment.Center
            ) {
                // Subtle map grid background styling
                Canvas(modifier = Modifier.matchParentSize()) {
                    val strokeColor = Color(0xFFE2E8F0)
                    val step = 28.dp.toPx()
                    var x = 0f
                    while (x < size.width) {
                        drawLine(strokeColor, Offset(x, 0f), Offset(x, size.height), strokeWidth = 1f)
                        x += step
                    }
                    var y = 0f
                    while (y < size.height) {
                        drawLine(strokeColor, Offset(0f, y), Offset(size.width, y), strokeWidth = 1f)
                        y += step
                    }
                }

                // Coordinates pill badge
                val latStr = officeLocation?.let { String.format(Locale.US, "%.4f", it.latitude) } ?: "40.7128"
                val lonStr = officeLocation?.let { String.format(Locale.US, "%.4f", it.longitude) } ?: "-74.0068"

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(Color.White.copy(alpha = 0.94f))
                        .border(1.dp, Color(0xFFCBD5E1), RoundedCornerShape(20.dp))
                        .padding(horizontal = 14.dp, vertical = 8.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.MyLocation,
                            contentDescription = "Coordinates",
                            modifier = Modifier.size(15.dp),
                            tint = Color(0xFF2563EB)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Lat: $latStr, Lon: $lonStr",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color(0xFF334155)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Explanatory guidance text
            Text(
                text = "To mark your attendance, ensure your current office location is correctly identified.",
                fontSize = 13.sp,
                color = Color(0xFF64748B),
                textAlign = TextAlign.Center,
                lineHeight = 18.sp,
                modifier = Modifier.padding(horizontal = 8.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Outlined Set Office Location Button
            OutlinedButton(
                onClick = onSetLocationClick,
                enabled = !isLoading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(24.dp),
                border = androidx.compose.foundation.BorderStroke(1.5.dp, Color(0xFF2563EB)),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = Color(0xFF2563EB)
                ),
                contentPadding = PaddingValues(horizontal = 16.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.MyLocation,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = Color(0xFF2563EB)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (isLoading) "Updating Coordinates..." else "Set Office Location",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFF2563EB)
                )
            }
        }
    }
}
