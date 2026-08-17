package com.github.amapkit.map.overlays.polygon

import com.amap.api.maps.model.AMapPara
import com.amap.api.maps.model.BaseHoleOptions
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.PolygonOptions

/** 通过 [PolygonOptionsSink] 接口逐步设置字段，最终构建 AMap [PolygonOptions]。 */
class PolygonBuilder : PolygonOptionsSink {
    private val polygonOptions: PolygonOptions = PolygonOptions()

    fun build() = polygonOptions

    override fun setFillColor(color: Int) {
        polygonOptions.fillColor(color)
    }

    override fun setStrokeColor(color: Int) {
        polygonOptions.strokeColor(color)
    }

    override fun setStrokeWidth(width: Float) {
        polygonOptions.strokeWidth(width)
    }

    override fun setVisible(visible: Boolean) {
        polygonOptions.visible(visible)
    }

    override fun setZIndex(zIndex: Float) {
        polygonOptions.zIndex(zIndex)
    }

    override fun setPoints(points: MutableList<LatLng?>?) {
        polygonOptions.points = points
    }

    override fun setHoles(holes: List<BaseHoleOptions>?) {
        if (holes != null) {
            polygonOptions.addHoles(holes)
        }
    }

    override fun setLineJoinType(joinType: AMapPara.LineJoinType?) {
        polygonOptions.lineJoinType(joinType)
    }
}
