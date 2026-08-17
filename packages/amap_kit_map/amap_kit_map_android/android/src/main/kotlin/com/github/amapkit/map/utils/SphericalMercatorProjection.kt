package com.github.amapkit.map.utils

import com.amap.api.maps.model.LatLng
import kotlin.math.atan
import kotlin.math.exp
import kotlin.math.ln
import kotlin.math.sin

class SphericalMercatorProjection(private val worldWidth: Double) {
    fun toPoint(latLng: LatLng): Point {
        val x: Double = latLng.longitude / 360 + .5
        val siny = sin(Math.toRadians(latLng.latitude))
        val y = 0.5 * ln((1 + siny) / (1 - siny)) / -(2 * Math.PI) + .5

        return Point(x * worldWidth, y * worldWidth)
    }

    fun toLatLng(point: Point): LatLng {
        val x: Double = point.x / worldWidth - 0.5
        val lng = x * 360

        val y: Double = .5 - (point.y / worldWidth)
        val lat = 90 - Math.toDegrees(atan(exp(-y * 2 * Math.PI)) * 2)

        return LatLng(lat, lng)
    }
}
