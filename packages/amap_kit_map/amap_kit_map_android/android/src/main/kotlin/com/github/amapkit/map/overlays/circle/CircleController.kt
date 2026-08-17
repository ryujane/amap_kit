package com.github.amapkit.map.overlays.circle

import com.amap.api.maps.model.Circle
import com.amap.api.maps.model.LatLng

/** Owns one AMap circle and applies incremental style updates. */
class CircleController(private val circle: Circle) : CircleOptionsSink {

    val amapCircleId: String = circle.id

    fun remove() {
        circle.remove()
    }

    override fun setCenter(center: LatLng) {
        circle.center = center
    }

    override fun setRadius(radius: Double) {
        circle.radius = radius
    }

    override fun setStrokeWidth(width: Float) {
        circle.strokeWidth = width
    }

    override fun setStrokeColor(color: Int) {
        circle.strokeColor = color
    }

    override fun setFillColor(color: Int) {
        circle.fillColor = color
    }

    override fun setVisible(visible: Boolean) {
        circle.isVisible = visible
    }

    override fun setZIndex(zIndex: Float) {
        circle.zIndex = zIndex
    }

    override fun setStrokeDottedLineType(type: Int) {
        circle.strokeDottedLineType = type
    }
}
