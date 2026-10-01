package com.monjur.employeeattendance.domain.model

enum class SimulationMode(val label: String) {
    REAL_GPS("Real GPS (Live Sensor)"),
    SIMULATE_IN_RANGE("Simulate 25m (In Range)"),
    SIMULATE_OUT_OF_RANGE("Simulate 120m (Out of Range)")
}
