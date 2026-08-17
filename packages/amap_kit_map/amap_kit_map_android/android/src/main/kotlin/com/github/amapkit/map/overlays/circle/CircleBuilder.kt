package com.github.amapkit.map.overlays.circle

import com.amap.api.maps.model.CircleOptions
import com.amap.api.maps.model.LatLng

/** 通过 [CircleOptionsSink] 接口逐步设置字段，最终构建 AMap [CircleOptions]。 */
class CircleBuilder : CircleOptionsSink {
    private val circleOptions: CircleOptions = CircleOptions()

    fun build() = circleOptions

    override fun setCenter(center: LatLng) {
        circleOptions.center(center)
    }

    override fun setRadius(radius: Double) {
        circleOptions.radius(radius)
    }

    override fun setStrokeWidth(width: Float) {
        circleOptions.strokeWidth(width)
    }

    override fun setStrokeColor(color: Int) {
        circleOptions.strokeColor(color)
    }

    override fun setFillColor(color: Int) {
        circleOptions.fillColor(color)
    }

    override fun setVisible(visible: Boolean) {
        circleOptions.visible(visible)
    }

    override fun setZIndex(zIndex: Float) {
        circleOptions.zIndex(zIndex)
    }

    override fun setStrokeDottedLineType(type: Int) {
        circleOptions.setStrokeDottedLineType(type)
    }
}
