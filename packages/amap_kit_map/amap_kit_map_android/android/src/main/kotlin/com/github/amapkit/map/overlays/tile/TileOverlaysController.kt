package com.github.amapkit.map.overlays.tile

import com.amap.api.maps.AMap
import com.github.amapkit.map.Convert
import com.github.amapkit.map.FlutterError
import com.github.amapkit.map.MapsCallbackApi
import com.github.amapkit.map.PlatformTileOverlay
import com.github.amapkit.map.PlatformTileOverlayUpdates

/** Owns every custom tile overlay belonging to one map instance. */
class TileOverlaysController(
    private val map: AMap,
    private val flutterApi: MapsCallbackApi
) {
    private val controllers = mutableMapOf<String, TileOverlayController>()

    fun update(updates: PlatformTileOverlayUpdates) {
        updates.toRemove.forEach(::remove)
        updates.toChange.forEach(::change)
        updates.toAdd.forEach(::add)
    }

    fun addTileOverlays(overlays: List<PlatformTileOverlay>) {
        overlays.forEach(::add)
    }

    fun clearTileCache(id: String) {
        controllers[id]?.clearTileCache() ?: throw FlutterError(
            "unknown_tile_overlay",
            "Unknown tile overlay ID: $id"
        )
    }

    fun dispose() {
        controllers.values.forEach(TileOverlayController::remove)
        controllers.clear()
    }

    private fun add(options: PlatformTileOverlay) {
        val provider = TileProviderController(
            flutterApi,
            options.id,
            options.tileSize.toInt()
        )
        val builder = TileOverlayBuilder()
        val id = Convert.interpretTileOverlayOptions(options, builder, provider)
        controllers.remove(id)?.remove()
        controllers[id] = TileOverlayController(map, builder.build())
    }

    private fun change(options: PlatformTileOverlay) {
        controllers[options.id]?.let { controller ->
            if (controller.currentTileSize != options.tileSize.toInt()) {
                controller.replaceTileProvider(
                    TileProviderController(
                        flutterApi,
                        options.id,
                        options.tileSize.toInt()
                    )
                )
            }
            Convert.interpretTileOverlayOptions(options, controller, controller.tileProvider)
            controller.applyChanges()
        } ?: add(options)
    }

    private fun remove(id: String) {
        controllers.remove(id)?.remove()
    }
}
