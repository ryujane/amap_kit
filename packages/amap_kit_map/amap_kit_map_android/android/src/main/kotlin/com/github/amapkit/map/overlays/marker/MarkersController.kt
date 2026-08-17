package com.github.amapkit.map.overlays.marker

import android.content.res.AssetManager
import androidx.annotation.VisibleForTesting
import com.amap.api.maps.AMap
import com.amap.api.maps.model.Marker
import com.github.amapkit.map.Convert
import com.github.amapkit.map.FlutterError
import com.github.amapkit.map.MapsCallbackApi
import com.github.amapkit.map.PlatformMarker
import com.github.amapkit.map.collections.MarkerCollection
import com.github.amapkit.map.collections.MarkerManager
import com.github.amapkit.map.overlays.clustering.ClusterManager
import com.github.amapkit.map.overlays.clustering.ClusterManagersController

class MarkersController(
    private val flutterApi: MapsCallbackApi,
    private val density: Float,
    private val assetManager: AssetManager,
    private val bitmapDescriptorFactoryWrapper: Convert.BitmapDescriptorFactoryWrapper,
    private val clusterManagersController: ClusterManagersController,
    markerManager: MarkerManager
) : AMap.OnMarkerClickListener, AMap.OnMarkerDragListener,
    ClusterManager.OnClusterItemClickListener<MarkerBuilder>,
    ClusterManager.OnClusterItemInfoWindowClickListener<MarkerBuilder>,
    ClusterManagersController.OnClusterItemRendered<MarkerBuilder> {

    private val markerIdToMarkerBuilder = mutableMapOf<String, MarkerBuilder>()
    private val markerIdToController = mutableMapOf<String, MarkerController>()
    private val amapMarkerIdToDartMarkerId = mutableMapOf<String, String>()
    private val markerCollection = markerManager.createCollection()

    init {
        markerCollection.markerDragListener = this
        markerCollection.markerClickListener = this
        setClusterItemRenderedListener(this)
        setClusterItemClickListener(this)
        setClusterItemInfoWindowClickListener(this)
    }

    fun addMarkers(toAdd: List<PlatformMarker>) {
        val markersByCluster = mutableMapOf<String, MutableList<MarkerBuilder>>()
        val nonClusteredMarkers = mutableListOf<MarkerBuilder>()

        for (marker in toAdd) {
            removeMarkers(listOf(marker.markerId))
            val markerBuilder = MarkerBuilder(marker.markerId, marker.clusterManagerId)
            Convert.interpretMarkerOptions(
                marker,
                markerBuilder,
                assetManager,
                density,
                bitmapDescriptorFactoryWrapper
            )
            markerIdToMarkerBuilder[marker.markerId] = markerBuilder
            if (marker.clusterManagerId == null) {
                nonClusteredMarkers += markerBuilder
            } else {
                markersByCluster.getOrPut(marker.clusterManagerId) { mutableListOf() } += markerBuilder
            }
        }

        // Add non-clustered markers to the map
        nonClusteredMarkers.forEach { markerBuilder ->
            addMarkerToMap(markerBuilder.markerId, markerBuilder)
        }

        // Batch add clustered markers
        markersByCluster.forEach { (clusterManagerId, markers) ->
            clusterManagersController.addItems(clusterManagerId, markers)
        }
    }

    fun updateMarkers(toUpdates: List<PlatformMarker>) {
        // Collect markers that need cluster manager changes for batch processing
        val markersToAddByCluster = mutableMapOf<String, MutableList<MarkerBuilder>>()
        val markersToRemoveByCluster = mutableMapOf<String, MutableList<MarkerBuilder>>()

        for (markerToChange in toUpdates) {
            val markerId = markerToChange.markerId
            val markerBuilder = markerIdToMarkerBuilder[markerId] ?: continue
            val newClusterManagerId = markerToChange.clusterManagerId
            val oldClusterManagerId = markerBuilder.clusterManagerId
            if (newClusterManagerId != oldClusterManagerId) {
                // Remove from old cluster manager
                if (oldClusterManagerId != null) {
                    markersToRemoveByCluster.getOrPut(oldClusterManagerId) { mutableListOf() } +=
                        markerBuilder
                }
                // Prepare new marker for addition
                val newMarkerBuilder = MarkerBuilder(markerId, newClusterManagerId)
                Convert.interpretMarkerOptions(
                    markerToChange,
                    newMarkerBuilder,
                    assetManager,
                    density,
                    bitmapDescriptorFactoryWrapper
                )
                markerIdToMarkerBuilder[markerId] = newMarkerBuilder

                if (newClusterManagerId != null) {
                    markersToAddByCluster.getOrPut(newClusterManagerId) { mutableListOf() } +=
                        newMarkerBuilder
                } else {
                    // Add to map immediately if not clustered
                    addMarkerToMap(markerId, newMarkerBuilder)
                }
                // Clean up old marker controller if it's not clustered
                if (oldClusterManagerId == null) {
                    markerIdToController.remove(markerId)?.let { oldController ->
                        oldController.remove()
                        amapMarkerIdToDartMarkerId.remove(oldController.id)
                    }
                }
            } else {
                // Update existing marker in place
                Convert.interpretMarkerOptions(
                    markerToChange,
                    markerBuilder,
                    assetManager,
                    density,
                    bitmapDescriptorFactoryWrapper
                )
                markerIdToController[markerId]?.let { controller ->
                    Convert.interpretMarkerOptions(
                        markerToChange,
                        controller,
                        assetManager,
                        density,
                        bitmapDescriptorFactoryWrapper
                    )
                }
            }
        }

        // Batch remove from cluster managers
        markersToRemoveByCluster.forEach { (clusterManagerId, markers) ->
            clusterManagersController.removeItems(clusterManagerId, markers)
        }
        // Batch add to cluster managers
        markersToAddByCluster.forEach { (clusterManagerId, markers) ->
            clusterManagersController.addItems(clusterManagerId, markers)
        }
    }

    fun removeMarkers(toRemoves: List<String>) {
        // Group markers by cluster manager ID for batch operations
        val markersByCluster = mutableMapOf<String, MutableList<MarkerBuilder>>()
        val nonClusteredControllers = mutableListOf<MarkerController>()

        for (markerId in toRemoves) {
            val markerBuilder = markerIdToMarkerBuilder[markerId] ?: continue
            val clusterManagerId = markerBuilder.clusterManagerId
            if (clusterManagerId != null) {
                markersByCluster.getOrPut(clusterManagerId) { mutableListOf() } += markerBuilder
            } else {
                markerIdToController[markerId]?.let(nonClusteredControllers::add)
            }
        }
        // Batch remove clustered markers
        markersByCluster.forEach { (clusterManagerId, markers) ->
            clusterManagersController.removeItems(clusterManagerId, markers)
        }
        // Remove non-clustered markers from the map
        nonClusteredControllers.forEach(MarkerController::remove)

        // Clean up all marker references
        for (markerId in toRemoves) {
            markerIdToMarkerBuilder.remove(markerId)
            markerIdToController.remove(markerId)?.let { markerController ->
                amapMarkerIdToDartMarkerId.remove(markerController.id)
            }
        }
    }

    private fun addMarkerToMap(markerId: String, markerBuilder: MarkerBuilder) {
        val marker = markerCollection.addMarker(markerBuilder.build())
        createControllerForMarker(markerId, marker, markerBuilder.consumeTapEvents)
    }

    private fun createControllerForMarker(
        markerId: String,
        marker: Marker,
        consumeTapEvents: Boolean
    ) {
        val controller = MarkerController(marker, consumeTapEvents)
        markerIdToController[markerId] = controller
        amapMarkerIdToDartMarkerId[marker.id] = markerId
    }

    override fun onMarkerClick(marker: Marker?): Boolean {
        val markerId = marker?.let { amapMarkerIdToDartMarkerId[it.id] } ?: return false
        flutterApi.onMarkerTap(markerId) { }
        val consumeTapEvents = markerIdToController[markerId]?.consumeTapEvents ?: false
//        if (!consumeTapEvents) {
//            // 未消费点击时显式展示信息窗，兜底保证点按 marker 即显示标题/副标题。
//            marker.showInfoWindow()
//        }
        return consumeTapEvents
    }

    override fun onMarkerDragStart(marker: Marker?) {
        marker ?: return
        val markerId = amapMarkerIdToDartMarkerId[marker.id] ?: return
        flutterApi.onMarkerDragStart(markerId, Convert.latLngToPigeon(marker.position)) { }
    }

    override fun onMarkerDrag(marker: Marker?) {
        marker ?: return
        val markerId = amapMarkerIdToDartMarkerId[marker.id] ?: return
        flutterApi.onMarkerDrag(markerId, Convert.latLngToPigeon(marker.position)) { }
    }

    override fun onMarkerDragEnd(marker: Marker?) {
        marker ?: return
        val markerId = amapMarkerIdToDartMarkerId[marker.id] ?: return
        flutterApi.onMarkerDragEnd(markerId, Convert.latLngToPigeon(marker.position)) { }
    }

    fun dispose() {
        markerCollection.markerDragListener = null
        markerCollection.markerClickListener = null
        markerCollection.clear()
        setClusterItemClickListener(null)
        setClusterItemRenderedListener(null)
        setClusterItemInfoWindowClickListener(null)
        markerIdToMarkerBuilder.clear()
        markerIdToController.clear()
        amapMarkerIdToDartMarkerId.clear()
    }

    override fun onClusterItemClick(item: MarkerBuilder): Boolean {
        val markerId = item.markerId
        flutterApi.onMarkerTap(markerId) { }
        return markerIdToController[markerId]?.consumeTapEvents ?: false
    }

    override fun onClusterItemInfoWindowClick(item: MarkerBuilder) {
        flutterApi.onInfoWindowTap(item.markerId) { }
    }

    override fun onClusterItemRendered(item: MarkerBuilder, marker: Marker) {
        val markerId = item.markerId
        if (markerIdToMarkerBuilder[markerId] == item) {
            createControllerForMarker(item.markerId, marker, item.consumeTapEvents)
        }
    }

    fun showMarkerInfoWindow(markerId: String) {
        val markerController = markerIdToController[markerId] ?: throw FlutterError(
            "Invalid markerId", "showInfoWindow called with invalid markerId", null
        )
        markerController.showInfoWindow()
    }

    fun hideMarkerInfoWindow(markerId: String) {
        val markerController = markerIdToController[markerId] ?: throw FlutterError(
            "Invalid markerId", "hideInfoWindow called with invalid markerId", null
        )
        markerController.hideInfoWindow()
    }

    fun isInfoWindowShown(markerId: String): Boolean {
        val markerController = markerIdToController[markerId] ?: throw FlutterError(
            "Invalid markerId", "isInfoWindowShown called with invalid markerId", null
        )
        return markerController.isInfoWindowShown
    }


    @VisibleForTesting
    fun setClusterItemClickListener(
        listener: ClusterManager.OnClusterItemClickListener<MarkerBuilder>?) {
        clusterManagersController.setClusterItemClickListener(listener)
    }

    @VisibleForTesting
    fun setClusterItemInfoWindowClickListener(listener: ClusterManager.OnClusterItemInfoWindowClickListener<MarkerBuilder>?) {

        clusterManagersController.setClusterItemInfoWindowClickListener(listener)
    }

    @VisibleForTesting
    fun setClusterItemRenderedListener(listener: ClusterManagersController.OnClusterItemRendered<MarkerBuilder>?) {
        clusterManagersController.setClusterItemRenderedListener(listener)
    }
}
