package com.github.amapkit.map.overlays.circle

import com.amap.api.maps.model.LatLng

/**
 */
interface CircleOptionsSink {
    //圆心
    fun setCenter(center: LatLng)

    //半径（米）
    fun setRadius(radius: Double)

    //边框宽度
    fun setStrokeWidth(width: Float)

    //边框颜色
    fun setStrokeColor(color: Int)

    //填充颜色
    fun setFillColor(color: Int)

    //是否显示
    fun setVisible(visible: Boolean)

    //层级
    fun setZIndex(zIndex: Float)

    //边框虚线类型（AMap 的 Circle 通过 setStrokeDottedLineType 指定，-1 为默认实线）
    fun setStrokeDottedLineType(type: Int)
}
