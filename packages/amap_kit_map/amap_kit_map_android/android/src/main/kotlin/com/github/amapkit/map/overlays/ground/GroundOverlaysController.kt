package com.github.amapkit.map.overlays.ground

import android.content.res.AssetManager
import com.amap.api.maps.AMap
import com.amap.api.maps.model.GroundOverlay
import com.github.amapkit.map.Convert
import com.github.amapkit.map.PlatformGroundOverlay
import com.github.amapkit.map.PlatformGroundOverlayUpdates

class GroundOverlaysController(
    private val map: AMap,
    private val assetManager: AssetManager,
    private val density: Float,
    private val bitmapDescriptorFactory: Convert.BitmapDescriptorFactoryWrapper
) {
    private val overlays = mutableMapOf<String, GroundOverlay>()

    fun update(updates: PlatformGroundOverlayUpdates) {
        updates.toRemove.forEach(::remove)
        updates.toChange.forEach(::replace)
        updates.toAdd.forEach(::replace)
    }

    fun addGroundOverlays(overlays: List<PlatformGroundOverlay>) {
        overlays.forEach(::replace)
    }

    fun dispose() {
        overlays.values.forEach(::release)
        overlays.clear()
    }

    private fun replace(value: PlatformGroundOverlay) {
        remove(value.id)
        val builder = GroundOverlayBuilder()
        Convert.interpretGroundOverlayOptions(
            value,
            builder,
            assetManager,
            density,
            bitmapDescriptorFactory
        )
        overlays[value.id] = map.addGroundOverlay(builder.build())
    }

    private fun remove(id: String) {
        overlays.remove(id)?.let(::release)
    }

    private fun release(overlay: GroundOverlay) {
        overlay.remove()
        overlay.destroy()
    }
}
