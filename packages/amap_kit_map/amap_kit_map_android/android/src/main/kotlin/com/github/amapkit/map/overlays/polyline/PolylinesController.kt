package com.github.amapkit.map.overlays.polyline

import android.content.res.AssetManager
import com.amap.api.maps.AMap
import com.amap.api.maps.model.Polyline
import com.github.amapkit.map.Convert
import com.github.amapkit.map.MapsCallbackApi
import com.github.amapkit.map.PlatformPolyline

class PolylinesController(
    private val map: AMap,
    private val flutterApi: MapsCallbackApi,
    private val density: Float,
    private val assetManager: AssetManager
) : AMap.OnPolylineClickListener {


    private val polylineControllers = mutableMapOf<String, PolylineController>()
    private val dartPolylineIdsByAmapId = mutableMapOf<String, String>()

    init {
        map.setOnPolylineClickListener(this)
    }

    fun addPolylines(polylinesToAdd: List<PlatformPolyline>) =
        polylinesToAdd.forEach(::addPolyline)

    fun changePolylines(polylinesToChange: List<PlatformPolyline>) =
        polylinesToChange.forEach(::changePolyline)

    fun removePolylines(polylineIdsToRemove: List<String?>) {
        polylineIdsToRemove.forEach { polylineId ->
            polylineControllers.remove(polylineId)?.let { controller ->
                controller.remove()
                dartPolylineIdsByAmapId.remove(controller.amapPolylineId)
            }
        }
    }

    private fun addPolyline(polyline: PlatformPolyline) {
        val polylineBuilder = PolylineBuilder(density)
        val polylineId =
            Convert.interpretPolylineOptions(polyline, polylineBuilder, assetManager, density)
        polylineControllers.remove(polylineId)?.let { oldController ->
            oldController.remove()
            dartPolylineIdsByAmapId.remove(oldController.amapPolylineId)
        }
        val amapPolyline: Polyline = map.addPolyline(polylineBuilder.build())
        polylineControllers[polylineId] =
            PolylineController(amapPolyline, polylineBuilder.consumeTapEvents, density)
        dartPolylineIdsByAmapId[amapPolyline.id] = polylineId
    }

    private fun changePolyline(polyline: PlatformPolyline) {
        polylineControllers[polyline.polylineId]?.let { polylineController ->
            Convert.interpretPolylineOptions(polyline, polylineController, assetManager, density)
        }
    }

    override fun onPolylineClick(polyline: Polyline) {
        val polylineId = dartPolylineIdsByAmapId[polyline.id] ?: return
        flutterApi.onPolylineTap(polylineId) { }
    }

    fun dispose() {
        map.setOnPolylineClickListener(null)
        polylineControllers.values.forEach(PolylineController::remove)
        polylineControllers.clear()
        dartPolylineIdsByAmapId.clear()
    }
}
