package com.github.amapkit.map.overlays.ground

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds

interface GroundOverlayOptionsSink {
    fun setImage(image: BitmapDescriptor)
    fun setPosition(position: LatLng, width: Float, height: Float?)
    fun setPositionFromBounds(bounds: LatLngBounds)
    fun setAnchor(anchorU: Float, anchorV: Float)
    fun setBearing(bearing: Float)
    fun setTransparency(transparency: Float)
    fun setZIndex(zIndex: Float)
    fun setVisible(visible: Boolean)
}
