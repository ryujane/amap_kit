package com.github.amapkit.map.utils

import com.amap.api.maps.model.LatLng
import kotlin.math.atan
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.sin

data class Point(val x: Double, val y: Double)

fun toPoint(latLng: LatLng): Point {
    val x = latLng.longitude / 360 + 0.5
    val sinLatitude = sin(Math.toRadians(latLng.latitude))
    val y = 0.5 * ln((1 + sinLatitude) / (1 - sinLatitude)) / -(2 * Math.PI) + 0.5
    return Point(x, y)
}

fun toLatLng(point: Point): LatLng {
    val longitude = (point.x - 0.5) * 360
    val latitude = 90 - Math.toDegrees(
        atan(exp(-(0.5 - point.y) * 2 * Math.PI)) * 2
    )
    return LatLng(latitude, longitude)
}
