package com.github.amapkit.map.overlays.ground

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.GroundOverlayOptions
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds

class GroundOverlayBuilder : GroundOverlayOptionsSink {
    private val options = GroundOverlayOptions()

    fun build(): GroundOverlayOptions = options

    override fun setImage(image: BitmapDescriptor) {
        options.image(image)
    }

    override fun setPosition(position: LatLng, width: Float, height: Float?) {
        if (height == null) {
            options.position(position, width)
        } else {
            options.position(position, width, height)
        }
    }

    override fun setPositionFromBounds(bounds: LatLngBounds) {
        options.positionFromBounds(bounds)
    }

    override fun setAnchor(anchorU: Float, anchorV: Float) {
        options.anchor(anchorU, anchorV)
    }

    override fun setBearing(bearing: Float) {
        options.bearing(bearing)
    }

    override fun setTransparency(transparency: Float) {
        options.transparency(transparency)
    }

    override fun setZIndex(zIndex: Float) {
        options.zIndex(zIndex)
    }

    override fun setVisible(visible: Boolean) {
        options.visible(visible)
    }
}
