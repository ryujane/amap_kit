package com.github.amapkit.map.overlays.polygon

import com.amap.api.maps.AMap
import com.amap.api.maps.model.PolygonOptions
import com.github.amapkit.map.Convert
import com.github.amapkit.map.PlatformPolygon

/** Maintains every polygon belonging to one map instance. */
class PolygonsController(private val map: AMap) {

    private val polygonControllers = mutableMapOf<String, PolygonController>()

    fun addPolygons(polygonsToAdd: List<PlatformPolygon>) = polygonsToAdd.forEach(::addPolygon)

    fun changePolygons(polygonsToChange: List<PlatformPolygon>) =
        polygonsToChange.forEach(::changePolygon)

    fun removePolygons(polygonIdsToRemove: List<String>) {
        polygonIdsToRemove.forEach { polygonControllers.remove(it)?.remove() }
    }

    fun dispose() {
        polygonControllers.values.forEach(PolygonController::remove)
        polygonControllers.clear()
    }

    private fun addPolygon(polygon: PlatformPolygon) {
        val polygonBuilder = PolygonBuilder()
        Convert.interpretPolygonOptions(polygon, polygonBuilder)
        addPolygon(polygon.polygonId, polygonBuilder.build())
    }

    private fun addPolygon(polygonId: String, polygonOptions: PolygonOptions) {
        polygonControllers.remove(polygonId)?.remove()
        polygonControllers[polygonId] = PolygonController(map.addPolygon(polygonOptions))
    }

    private fun changePolygon(polygon: PlatformPolygon) {
        polygonControllers[polygon.polygonId]?.let { polygonController ->
            Convert.interpretPolygonOptions(polygon, polygonController)
        }
    }
}
