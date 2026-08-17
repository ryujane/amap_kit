package com.github.amapkit.map.overlays.polyline

import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.PolylineOptions

 interface PolylineOptionsSink {
    //路线点
    fun setPoints(points: MutableList<LatLng?>?)

    //宽度
    fun setWidth(width: Float)

    //颜色
    fun setColor(color: Int)

    //是否显示
    fun setVisible(visible: Boolean)

    //纹理
    fun setCustomTexture(customTexture: BitmapDescriptor?)

    //纹理列表
    fun setCustomTextureList(customTextureList: MutableList<BitmapDescriptor?>?)

    //颜色列表
    fun setColorList(colorList: MutableList<Int?>?)

    //纹理顺序
    fun setCustomIndexList(customIndexList: MutableList<Int?>?)

    //是否大地曲线
    fun setGeodesic(geodesic: Boolean)

    //是否渐变
    fun setGradient(gradient: Boolean)

    //透明度
    fun setAlpha(alpha: Float)

    //虚线类型
    fun setDashLineType(type: Int)

    //是否虚线
    fun setDashLine(dashLine: Boolean)

    //线冒类型
    fun setLineCapType(lineCapType: PolylineOptions.LineCapType?)

    //线交接类型
    fun setLineJoinType(joinType: PolylineOptions.LineJoinType?)

    fun setConsumeTapEvents(consumeTapEvents: Boolean)

    fun setZIndex(zIndex: Float)
}
