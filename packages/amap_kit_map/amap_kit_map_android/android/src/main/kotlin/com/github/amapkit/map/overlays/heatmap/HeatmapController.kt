package com.github.amapkit.map.overlays.heatmap

import com.amap.api.maps.AMap
import com.amap.api.maps.model.Gradient
import com.amap.api.maps.model.HeatmapTileProvider
import com.amap.api.maps.model.TileOverlay
import com.amap.api.maps.model.TileOverlayOptions
import com.amap.api.maps.model.WeightedLatLng

/** Owns one heatmap and rebuilds its immutable AMap tile provider after updates. */
class HeatmapController(
    private val map: AMap,
    initialOptions: HeatmapOptions
) : HeatmapOptionsSink {
    private var data = initialOptions.data
    private var gradient = initialOptions.gradient
    private var opacity = initialOptions.opacity
    private var radius = initialOptions.radius
    private var visible = initialOptions.visible
    private var overlay: TileOverlay? = createOverlay()

    fun applyChanges() {
        overlay?.remove()
        overlay = createOverlay()
    }

    fun remove() {
        overlay?.remove()
        overlay = null
    }

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

    private fun createOverlay(): TileOverlay? {
        if (data.isEmpty()) return null
        val builder = HeatmapTileProvider.Builder()
            .weightedData(data)
            .radius(radius)
            .transparency(opacity)
        // Omitting the gradient lets the SDK apply its own default.
        gradient?.let(builder::gradient)
        return map.addTileOverlay(
            TileOverlayOptions()
                .tileProvider(builder.build())
                .visible(visible)
        )
    }
}
