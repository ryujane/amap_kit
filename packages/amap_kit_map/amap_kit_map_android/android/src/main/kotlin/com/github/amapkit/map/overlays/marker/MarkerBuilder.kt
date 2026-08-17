package com.github.amapkit.map.overlays.marker

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.MarkerOptions
import com.github.amapkit.map.overlays.clustering.ClusterItem

open class MarkerBuilder(
    val markerId: String,
    var clusterManagerId: String?,
    private val markerOptions: MarkerOptions = MarkerOptions(),
) : MarkerOptionsSink, ClusterItem {
    var consumeTapEvents = false
        private set

    fun build() = markerOptions

    override fun setAlpha(alpha: Float) {
        markerOptions.alpha(alpha)
    }

    override fun setAnchor(u: Float, v: Float) {
        markerOptions.anchor(u, v)
    }


    override fun setDraggable(draggable: Boolean) {
        markerOptions.draggable(draggable)
    }

    override fun setFlat(flat: Boolean) {
        markerOptions.isFlat = flat
    }

    override fun setIcon(bitmapDescriptor: BitmapDescriptor?) {
        markerOptions.icon(bitmapDescriptor)
    }

    override fun setTitle(title: String?) {
        markerOptions.title(title)
    }


    override fun setSnippet(snippet: String?) {
        markerOptions.snippet(snippet)
    }

    override fun setPosition(position: LatLng?) {
        markerOptions.position(position)
    }

    override fun setRotation(rotation: Float) {
        markerOptions.rotateAngle(rotation)
    }

    override fun setVisible(visible: Boolean) {
        markerOptions.visible(visible)
    }

    override fun setZIndex(zIndex: Float) {
        markerOptions.zIndex(zIndex)
    }

    override fun setInfoWindowEnable(enable: Boolean) {
        markerOptions.infoWindowEnable(enable)
    }

    override fun setClickable(clickable: Boolean) {
    }

    override fun setConsumeTapEvents(consumeTapEvents: Boolean) {
        this.consumeTapEvents = consumeTapEvents
    }

    override val position: LatLng
        get() = markerOptions.position

    override val title: String?
        get() = markerOptions.title

    override val snippet: String?
        get() = markerOptions.snippet

    override val zIndex: Float?
        get() = markerOptions.zIndex

    /** Update existing markerOptions with builder values  */
    fun update(markerOptionsToUpdate: MarkerOptions) {
        markerOptionsToUpdate.alpha(markerOptions.alpha)
        markerOptionsToUpdate.anchor(markerOptions.anchorU, markerOptions.anchorV)
        markerOptionsToUpdate.draggable(markerOptions.isDraggable)
        markerOptionsToUpdate.isFlat=markerOptions.isFlat
        markerOptionsToUpdate.icon(markerOptions.icon)
        markerOptionsToUpdate.title(markerOptions.title)
        markerOptionsToUpdate.snippet(markerOptions.snippet)
        markerOptionsToUpdate.position(markerOptions.position)
        markerOptionsToUpdate.rotateAngle(markerOptions.rotateAngle)
        markerOptionsToUpdate.visible(markerOptions.isVisible)
        markerOptionsToUpdate.zIndex(markerOptions.zIndex)
    }
}
