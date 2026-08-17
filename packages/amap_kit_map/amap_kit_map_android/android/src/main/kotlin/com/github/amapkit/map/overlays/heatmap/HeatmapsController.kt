package com.github.amapkit.map.overlays.heatmap

import com.amap.api.maps.AMap
import com.github.amapkit.map.Convert
import com.github.amapkit.map.PlatformHeatmap
import com.github.amapkit.map.PlatformHeatmapUpdates

/** Owns every heatmap tile overlay belonging to one map instance. */
class HeatmapsController(private val map: AMap) {
    private val heatmapControllers = mutableMapOf<String, HeatmapController>()

    fun update(updates: PlatformHeatmapUpdates) {
        removeHeatmaps(updates.toRemove)
        changeHeatmaps(updates.toChange)
        addHeatmaps(updates.toAdd)
    }

    fun dispose() {
        heatmapControllers.values.forEach(HeatmapController::remove)
        heatmapControllers.clear()
    }

    fun addHeatmaps(heatmaps: List<PlatformHeatmap>) {
        heatmaps.forEach(::addHeatmap)
    }

    private fun changeHeatmaps(heatmaps: List<PlatformHeatmap>) {
        heatmaps.forEach { heatmap ->
            heatmapControllers[heatmap.id]?.let { controller ->
                Convert.interpretHeatmapOptions(heatmap, controller)
                controller.applyChanges()
            } ?: addHeatmap(heatmap)
        }
    }

    private fun removeHeatmaps(ids: List<String>) {
        ids.forEach { id -> heatmapControllers.remove(id)?.remove() }
    }

    private fun addHeatmap(heatmap: PlatformHeatmap) {
        val builder = HeatmapBuilder()
        val id = Convert.interpretHeatmapOptions(heatmap, builder)
        heatmapControllers.remove(id)?.remove()
        heatmapControllers[id] = HeatmapController(map, builder.build())
    }
}
