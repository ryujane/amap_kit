package com.github.amapkit.map.overlays.tile

import com.amap.api.maps.model.TileOverlayOptions
import com.amap.api.maps.model.TileProvider

/** Collects tile overlay options before creating the native overlay. */
class TileOverlayBuilder : TileOverlayOptionsSink {
    private lateinit var tileProvider: TileProvider
    private var tileSize = 256
    private var zIndex = 0f
    private var visible = true

    fun build(): TileOverlayBuildOptions =
        TileOverlayBuildOptions(tileProvider, tileSize, zIndex, visible)

    override fun setTileProvider(tileProvider: TileProvider) {
        this.tileProvider = tileProvider
    }

    override fun setTileSize(tileSize: Int) {
        this.tileSize = tileSize
    }

    override fun setZIndex(zIndex: Float) {
        this.zIndex = zIndex
    }

    override fun setVisible(visible: Boolean) {
        this.visible = visible
    }
}

/** Immutable construction snapshot for one native tile overlay. */
data class TileOverlayBuildOptions(
    val tileProvider: TileProvider,
    val tileSize: Int,
    val zIndex: Float,
    val visible: Boolean
) {
    fun toNativeOptions(): TileOverlayOptions = TileOverlayOptions()
        .tileProvider(tileProvider)
        .zIndex(zIndex)
        .visible(visible)
}
