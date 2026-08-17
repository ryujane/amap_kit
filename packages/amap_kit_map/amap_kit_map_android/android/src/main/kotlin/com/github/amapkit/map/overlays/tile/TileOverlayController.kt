package com.github.amapkit.map.overlays.tile

import com.amap.api.maps.AMap
import com.amap.api.maps.model.TileOverlay
import com.amap.api.maps.model.TileProvider

/** Owns one native tile overlay and its Dart provider bridge. */
class TileOverlayController(
    private val map: AMap,
    initialOptions: TileOverlayBuildOptions
) : TileOverlayOptionsSink {
    private var provider = initialOptions.tileProvider
    private var tileSize = initialOptions.tileSize
    private var zIndex = initialOptions.zIndex
    private var visible = initialOptions.visible
    private var overlay: TileOverlay? = map.addTileOverlay(initialOptions.toNativeOptions())
    private var requiresRebuild = false
    private var providerToDispose: TileProviderController? = null

    val tileProvider: TileProvider
        get() = provider

    val currentTileSize: Int
        get() = tileSize

    fun replaceTileProvider(tileProvider: TileProvider) {
        providerToDispose = provider as? TileProviderController
        provider = tileProvider
        requiresRebuild = true
    }

    override fun setTileProvider(tileProvider: TileProvider) {
        provider = tileProvider
    }

    override fun setTileSize(tileSize: Int) {
        requiresRebuild = requiresRebuild || this.tileSize != tileSize
        this.tileSize = tileSize
    }

    override fun setZIndex(zIndex: Float) {
        this.zIndex = zIndex
        overlay?.zIndex = zIndex
    }

    override fun setVisible(visible: Boolean) {
        this.visible = visible
        overlay?.isVisible = visible
    }

    fun applyChanges() {
        if (requiresRebuild) {
            overlay?.remove()
            overlay = map.addTileOverlay(
                TileOverlayBuildOptions(provider, tileSize, zIndex, visible).toNativeOptions()
            )
            providerToDispose?.dispose()
            providerToDispose = null
            requiresRebuild = false
        } else {
            // The Dart-side provider registry may now point at a replacement.
            // Clearing the cache makes the existing native provider bridge request it.
            overlay?.clearTileCache()
        }
    }

    fun clearTileCache() {
        overlay?.clearTileCache()
    }

    fun remove() {
        overlay?.remove()
        overlay = null
        (provider as? TileProviderController)?.dispose()
        providerToDispose?.dispose()
        providerToDispose = null
    }
}
