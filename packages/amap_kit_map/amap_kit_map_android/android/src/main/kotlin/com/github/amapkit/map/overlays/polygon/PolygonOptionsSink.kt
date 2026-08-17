package com.github.amapkit.map.overlays.polygon

import com.amap.api.maps.model.AMapPara
import com.amap.api.maps.model.BaseHoleOptions
import com.amap.api.maps.model.LatLng

/**
 * 多边形样式设置入口。实现为 [PolygonBuilder]（新建）或 [PolygonController]（增量变更）。
 *
 * 与 polyline 不同，AMap 的 Polygon 不支持 geodesic，也没有多边形点击监听，
 * 因此这里不提供对应的 setter；`onPolygonTap` 回调在 Android 上永不触发。
 */
interface PolygonOptionsSink {
    //填充颜色
    fun setFillColor(color: Int)

    //边框颜色
    fun setStrokeColor(color: Int)

    //边框宽度
    fun setStrokeWidth(width: Float)

    //是否显示
    fun setVisible(visible: Boolean)

    //层级
    fun setZIndex(zIndex: Float)

    //多边形顶点
    fun setPoints(points: MutableList<LatLng?>?)

    //洞（每个洞为一圈顶点，已转换为 AMap 的 BaseHoleOptions）
    fun setHoles(holes: List<BaseHoleOptions>?)

    //边框线交接类型。AMap Polygon 仅在创建时生效，创建后不支持修改
    fun setLineJoinType(joinType: AMapPara.LineJoinType?)
}
