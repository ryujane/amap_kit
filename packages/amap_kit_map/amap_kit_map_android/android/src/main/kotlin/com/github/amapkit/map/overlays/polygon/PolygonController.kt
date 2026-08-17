package com.github.amapkit.map.overlays.polygon

import com.amap.api.maps.model.AMapPara
import com.amap.api.maps.model.BaseHoleOptions
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.Polygon

/** Owns one AMap polygon and applies incremental style updates. */
class PolygonController(private val polygon: Polygon) : PolygonOptionsSink {

    val amapPolygonId: String = polygon.id

    fun remove() {
        polygon.remove()
    }

    override fun setFillColor(color: Int) {
        polygon.fillColor = color
    }

    override fun setStrokeColor(color: Int) {
        polygon.strokeColor = color
    }

    override fun setStrokeWidth(width: Float) {
        polygon.strokeWidth = width
    }

    override fun setVisible(visible: Boolean) {
        polygon.isVisible = visible
    }

    override fun setZIndex(zIndex: Float) {
        polygon.zIndex = zIndex
    }

    override fun setPoints(points: MutableList<LatLng?>?) {
        polygon.points = points
    }

    override fun setHoles(holes: List<BaseHoleOptions>?) {
        polygon.setHoleOptions(holes)
    }

    override fun setLineJoinType(joinType: AMapPara.LineJoinType?) {
        // AMap Polygon 创建后不支持修改 lineJoinType，仅在 add 路径（PolygonBuilder）生效。
    }
}
