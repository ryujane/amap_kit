package com.github.amapkit.map.overlays.tile

import com.amap.api.maps.model.TileProvider

/** Receives options supported by AMap's native tile overlay. */
interface TileOverlayOptionsSink {
    fun setTileProvider(tileProvider: TileProvider)
    fun setTileSize(tileSize: Int)
    fun setZIndex(zIndex: Float)
    fun setVisible(visible: Boolean)
}
