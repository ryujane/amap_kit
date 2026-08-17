package com.github.amapkit.map.overlays.polyline

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.PolylineOptions

class PolylineBuilder(private val density: Float) : PolylineOptionsSink {
    private val polylineOptions: PolylineOptions = PolylineOptions()
    var consumeTapEvents = false
        private set


    fun build() = polylineOptions

    override fun setPoints(points: MutableList<LatLng?>?) {
        polylineOptions.points = points
    }

    override fun setWidth(width: Float) {
        polylineOptions.width(width * density)
    }

    override fun setColor(color: Int) {
        polylineOptions.color(color)
    }

    override fun setVisible(visible: Boolean) {
        polylineOptions.visible(visible)
    }

    override fun setCustomTexture(customTexture: BitmapDescriptor?) {
        polylineOptions.customTexture = customTexture
    }

    override fun setCustomTextureList(customTextureList: MutableList<BitmapDescriptor?>?) {
        polylineOptions.customTextureList = customTextureList
    }

    override fun setColorList(colorList: MutableList<Int?>?) {
        polylineOptions.colorValues(colorList)
    }

    override fun setCustomIndexList(customIndexList: MutableList<Int?>?) {
        polylineOptions.customTextureIndex = customIndexList
    }

    override fun setGeodesic(geodesic: Boolean) {
        polylineOptions.geodesic(geodesic)
    }

    override fun setGradient(gradient: Boolean) {
        polylineOptions.useGradient(gradient)
    }

    override fun setAlpha(alpha: Float) {
        polylineOptions.transparency(alpha)
    }

    override fun setDashLineType(type: Int) {
        polylineOptions.dottedLineType = type
    }

    override fun setDashLine(dashLine: Boolean) {
        polylineOptions.isDottedLine = dashLine
    }

    override fun setLineCapType(lineCapType: PolylineOptions.LineCapType?) {
        polylineOptions.lineCapType(lineCapType)
    }

    override fun setLineJoinType(joinType: PolylineOptions.LineJoinType?) {
        polylineOptions.lineJoinType(joinType)
    }

    override fun setConsumeTapEvents(consumeTapEvents: Boolean) {
        this.consumeTapEvents = consumeTapEvents
    }

    override fun setZIndex(zIndex: Float) {
        polylineOptions.zIndex(zIndex)
    }
}
