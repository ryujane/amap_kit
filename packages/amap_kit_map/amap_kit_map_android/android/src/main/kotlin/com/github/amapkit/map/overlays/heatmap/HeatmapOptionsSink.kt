package com.github.amapkit.map.overlays.heatmap

import com.amap.api.maps.model.Gradient
import com.amap.api.maps.model.WeightedLatLng

/** Receives the platform-independent options needed to construct a heatmap. */
interface HeatmapOptionsSink {
    fun setData(data: List<WeightedLatLng>)
    fun setGradient(gradient: Gradient)
    fun setOpacity(opacity: Double)
    fun setRadius(radius: Int)
    fun setVisible(visible: Boolean)
}
