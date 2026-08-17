package com.github.amapkit.map.overlays.marker

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng

interface MarkerOptionsSink {

    fun setAlpha(alpha: Float)

    fun setAnchor(u: Float, v: Float)

    fun setDraggable(draggable: Boolean)

    fun setFlat(flat: Boolean)

    fun setIcon(bitmapDescriptor: BitmapDescriptor?)

    fun setTitle(title: String?)

    fun setSnippet(snippet: String?)

    fun setPosition(position: LatLng?)

    fun setRotation(rotation: Float)

    fun setVisible(visible: Boolean)

    fun setZIndex(zIndex: Float)

    fun setInfoWindowEnable(enable: Boolean)

    fun setClickable(clickable: Boolean)

    fun setConsumeTapEvents(consumeTapEvents: Boolean)

}