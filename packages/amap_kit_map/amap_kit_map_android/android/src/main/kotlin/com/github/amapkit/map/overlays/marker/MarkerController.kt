package com.github.amapkit.map.overlays.marker

import com.amap.api.maps.AMap
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Marker
import java.lang.ref.WeakReference

class MarkerController(marker: Marker, consumeTapEvents: Boolean) : MarkerOptionsSink {

    private val weakMarker = WeakReference(marker)
    val id: String = marker.id
    var consumeTapEvents = consumeTapEvents
        private set

    val isInfoWindowShown: Boolean
        get() = weakMarker.get()?.isInfoWindowShown ?: false

    fun remove() = weakMarker.get()?.remove()

    override fun setAlpha(alpha: Float) {
        val marker = weakMarker.get() ?: return
        marker.alpha = alpha
    }

    override fun setAnchor(u: Float, v: Float) {
        val marker = weakMarker.get() ?: return
        marker.setAnchor(u, v)
    }

    override fun setDraggable(draggable: Boolean) {
        val marker = weakMarker.get() ?: return
        marker.isDraggable = draggable
    }

    override fun setFlat(flat: Boolean) {
        val marker = weakMarker.get() ?: return
        marker.isFlat = flat
    }

    override fun setIcon(bitmapDescriptor: BitmapDescriptor?) {
        val marker = weakMarker.get() ?: return
        marker.setIcon(bitmapDescriptor)
    }

    override fun setTitle(title: String?) {
        val marker = weakMarker.get() ?: return
        marker.title = title
    }

    override fun setSnippet(snippet: String?) {
        val marker = weakMarker.get() ?: return
        marker.snippet = snippet
    }

    override fun setPosition(position: LatLng?) {
        val marker = weakMarker.get() ?: return
        marker.position = position
    }

    override fun setRotation(rotation: Float) {
        val marker = weakMarker.get() ?: return
        marker.rotateAngle = rotation
    }

    override fun setVisible(visible: Boolean) {
        val marker = weakMarker.get() ?: return
        marker.isVisible = visible
    }

    override fun setZIndex(zIndex: Float) {
        val marker = weakMarker.get() ?: return
        marker.zIndex = zIndex
    }

    override fun setInfoWindowEnable(enable: Boolean) {
        val marker = weakMarker.get() ?: return
        marker.isInfoWindowEnable = enable
    }

    override fun setClickable(clickable: Boolean) {
        val marker = weakMarker.get() ?: return
        marker.isClickable = clickable
    }

    override fun setConsumeTapEvents(consumeTapEvents: Boolean) {
        this.consumeTapEvents = consumeTapEvents
    }

    fun showInfoWindow() {
        val marker = weakMarker.get() ?: return
        marker.showInfoWindow()
    }

    fun hideInfoWindow() {
        val marker = weakMarker.get() ?: return
        marker.hideInfoWindow()
    }

}
