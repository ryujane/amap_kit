package com.github.amapkit.map.overlays.heatmap

import com.amap.api.maps.model.Gradient
import com.amap.api.maps.model.WeightedLatLng

/** Collects heatmap options before a native tile overlay is created. */
class HeatmapBuilder : HeatmapOptionsSink {
    private var data: List<WeightedLatLng> = emptyList()
    private var gradient: Gradient? = null
    private var opacity = 0.6
    private var radius = 12
    private var visible = true

    fun build() = HeatmapOptions(data, gradient, opacity, radius, visible)

    override fun setData(data: List<WeightedLatLng>) {
        this.data = data
    }

    override fun setGradient(gradient: Gradient) {
        this.gradient = gradient
    }

    override fun setOpacity(opacity: Double) {
        this.opacity = opacity
    }

    override fun setRadius(radius: Int) {
        this.radius = radius
    }

    override fun setVisible(visible: Boolean) {
        this.visible = visible
    }
}

/** Immutable native construction snapshot for one heatmap. */
data class HeatmapOptions(
    val data: List<WeightedLatLng>,
    // Null lets the native HeatmapTileProvider.Builder apply its SDK default.
    val gradient: Gradient?,
    val opacity: Double,
    val radius: Int,
    val visible: Boolean
)
