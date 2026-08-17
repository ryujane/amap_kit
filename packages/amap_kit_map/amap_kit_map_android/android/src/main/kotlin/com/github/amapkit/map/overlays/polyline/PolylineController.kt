package com.github.amapkit.map.overlays.polyline

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Polyline
import com.amap.api.maps.model.PolylineOptions

class PolylineController(
    private val polyline: Polyline,
    consumeTapEvents: Boolean,
    private val density: Float
) : PolylineOptionsSink {
    var consumeTapEvents = consumeTapEvents
        private set

    val amapPolylineId: String = polyline.id

    fun remove() {
        polyline.remove()
    }

    override fun setPoints(points: MutableList<LatLng?>?) {
        polyline.points = points
    }

    override fun setWidth(width: Float) {
        polyline.width = width * density
    }

    override fun setColor(color: Int) {
        polyline.color = color
    }

    override fun setVisible(visible: Boolean) {
        polyline.isVisible = visible
    }

    override fun setCustomTexture(customTexture: BitmapDescriptor?) {
        polyline.setCustomTexture(customTexture)
    }

    override fun setCustomTextureList(customTextureList: MutableList<BitmapDescriptor?>?) {
        polyline.setCustomTextureList(customTextureList)
    }

    override fun setColorList(colorList: MutableList<Int?>?) {
        val options = polyline.options
        options.colorValues(colorList)
        polyline.options = options

    }

    override fun setCustomIndexList(customIndexList: MutableList<Int?>?) {
        polyline.setCustomTextureIndex(customIndexList)
    }

    override fun setGeodesic(geodesic: Boolean) {
        polyline.isGeodesic = geodesic
    }

    override fun setGradient(gradient: Boolean) {
        val options = polyline.options
        options.useGradient(gradient)
        polyline.options = options
    }

    override fun setAlpha(alpha: Float) {
        polyline.setTransparency(alpha)
    }

    override fun setDashLineType(type: Int) {
        val options = polyline.options
        options.dottedLineType = type
        polyline.options = options
    }

    override fun setDashLine(dashLine: Boolean) {
        polyline.isDottedLine = dashLine
    }

    override fun setLineCapType(lineCapType: PolylineOptions.LineCapType?) {
        val options = polyline.options
        options.lineCapType(lineCapType)
        polyline.options = options
    }

    override fun setLineJoinType(joinType: PolylineOptions.LineJoinType?) {
        val options = polyline.options
        options.lineJoinType(joinType)
        polyline.options = options
    }

    override fun setConsumeTapEvents(consumeTapEvents: Boolean) {
        this.consumeTapEvents = consumeTapEvents
    }

    override fun setZIndex(zIndex: Float) {
        polyline.zIndex = zIndex
    }

}
