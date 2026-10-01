package com.monjur.employeeattendance.domain.model

data class OfficeLocation(
    val latitude: Double,
    val longitude: Double,
    val label: String = "Designated Office",
    val setTimestamp: Long = System.currentTimeMillis()
)
