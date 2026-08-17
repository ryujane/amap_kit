package com.github.amapkit.map.overlays.clustering

import android.content.Context
import com.amap.api.maps.AMap
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import com.github.amapkit.map.Convert
import com.github.amapkit.map.FlutterError
import com.github.amapkit.map.MapsCallbackApi
import com.github.amapkit.map.PlatformClusterManager
import com.github.amapkit.map.collections.MarkerManager
import com.github.amapkit.map.overlays.clustering.view.DefaultClusterRenderer
import com.github.amapkit.map.overlays.marker.MarkerBuilder

class ClusterManagersController(
    private val context: Context,
    private val flutterApi: MapsCallbackApi,
    private val map: AMap,
    private val markerManager: MarkerManager
) : ClusterManager.OnClusterClickListener<MarkerBuilder> {

    private val clusterManagers = mutableMapOf<String, ClusterManager<MarkerBuilder>>()

    private var clusterItemClickListener: ClusterManager.OnClusterItemClickListener<MarkerBuilder>? =
        null
    private var clusterItemInfoWindowClickListener: ClusterManager.OnClusterItemInfoWindowClickListener<MarkerBuilder>? =
        null

    private var clusterItemRenderedListener: OnClusterItemRendered<MarkerBuilder>? = null

    fun setClusterItemClickListener(
        listener: ClusterManager.OnClusterItemClickListener<MarkerBuilder>?
    ) {
        clusterItemClickListener = listener
        initListenersForClusterManagers()
    }

    fun setClusterItemInfoWindowClickListener(
        listener: ClusterManager.OnClusterItemInfoWindowClickListener<MarkerBuilder>?
    ) {
        clusterItemInfoWindowClickListener = listener
        initListenersForClusterManagers()
    }
    fun addClusterManagers(clusterManagersToAdd: List<PlatformClusterManager>) {
        clusterManagersToAdd.forEach { addClusterManager(it.id) }
    }

    fun addClusterManager(clusterManagerId: String) {
        removeClusterManager(clusterManagerId)
        clusterManagers[clusterManagerId] =
            ClusterManager<MarkerBuilder>(context, map, markerManager).also(::initializeRenderer)
    }

    private fun initializeRenderer(clusterManager: ClusterManager<MarkerBuilder>) {
        val clusterRenderer = MarkerClusterRenderer(context, map, clusterManager, this)
        clusterManager.setRenderer(clusterRenderer)
        initListenersForClusterManager(
            clusterManager, this, clusterItemClickListener, clusterItemInfoWindowClickListener
        )
    }

    private fun initListenersForClusterManagers() {
        clusterManagers.values.forEach { clusterManager ->
            initListenersForClusterManager(
                clusterManager, this, clusterItemClickListener, clusterItemInfoWindowClickListener
            )
        }
    }

    private fun initListenersForClusterManager(
        clusterManager: ClusterManager<MarkerBuilder>,
        clusterClickListener: ClusterManager.OnClusterClickListener<MarkerBuilder>?,
        clusterItemClickListener: ClusterManager.OnClusterItemClickListener<MarkerBuilder>?,
        clusterItemInfoWindowClickListener: ClusterManager.OnClusterItemInfoWindowClickListener<MarkerBuilder>?
    ) {
        clusterManager.clusterClickListener = clusterClickListener
        clusterManager.clusterItemClickListener = clusterItemClickListener
        clusterManager.clusterItemInfoWindowClickListener = clusterItemInfoWindowClickListener
    }

    fun removeClusterManagers(clusterManagerIdsToRemove: List<String>) {
        clusterManagerIdsToRemove.forEach(::removeClusterManager)
    }

    /**
     * Removes the manager from routing and clears its rendered items.
     */
    private fun removeClusterManager(clusterManagerId: String?) {
        clusterManagers.remove(clusterManagerId)?.apply {
            initListenersForClusterManager(this, null, null, null)
            clearItems()
            cluster()
        }
    }

    fun onCameraIdle() {
        clusterManagers.values.forEach(ClusterManager<MarkerBuilder>::cluster)
    }

    fun dispose() {
        clusterItemClickListener = null
        clusterItemInfoWindowClickListener = null
        clusterItemRenderedListener = null
        clusterManagers.values.forEach(ClusterManager<MarkerBuilder>::dispose)
        clusterManagers.clear()
    }

    fun addItem(item: MarkerBuilder) {
        val clusterManager = clusterManagers[item.clusterManagerId]
            ?: throw unknownClusterManager(item.clusterManagerId)
        clusterManager.addItem(item)
        clusterManager.cluster()
    }

    fun addItems(clusterManagerId: String?, items: MutableList<MarkerBuilder>) {
        val clusterManager = clusterManagers[clusterManagerId]
            ?: throw unknownClusterManager(clusterManagerId)
        clusterManager.addItems(items)
        clusterManager.cluster()
    }

    private fun unknownClusterManager(clusterManagerId: String?): FlutterError = FlutterError(
        "initialization_failed",
        "Marker references unknown cluster manager '$clusterManagerId'.",
        null
    )

    fun removeItems(clusterManagerId: String?, items: MutableList<MarkerBuilder>) {
        clusterManagers[clusterManagerId]?.let { clusterManager ->
            clusterManager.removeItems(items)
            clusterManager.cluster()
        }
    }

    fun setClusterItemRenderedListener(listener: OnClusterItemRendered<MarkerBuilder>?) {
        clusterItemRenderedListener = listener
    }

    override fun onClusterClick(cluster: Cluster<MarkerBuilder>): Boolean {
        cluster.items.firstOrNull()?.let { firstItem ->
            flutterApi.onClusterTap(
                Convert.clusterToPigeon(firstItem.clusterManagerId, cluster)
            ) { _: Result<Unit?>? -> }
        }
        return false
    }

    fun onClusterItemRendered(item: MarkerBuilder, marker: Marker) {
        // If map is being disposed, clusterItemRenderedListener might have been cleared and
        // set to null.
        clusterItemRenderedListener?.onClusterItemRendered(item, marker)
    }

    class MarkerClusterRenderer<T : MarkerBuilder>(
        context: Context,
        map: AMap,
        clusterManager: ClusterManager<T>,
        private val clusterManagersController: ClusterManagersController
    ) : DefaultClusterRenderer<T>(context, map, clusterManager) {
        override fun onBeforeClusterItemRendered(
            item: T,
            markerOptions: MarkerOptions
        ) {
            item.update(markerOptions)
        }

        override fun onClusterItemRendered(clusterItem: T, marker: Marker) {
            super.onClusterItemRendered(clusterItem, marker)
            clusterManagersController.onClusterItemRendered(clusterItem, marker)
        }
    }

    fun interface OnClusterItemRendered<T : ClusterItem> {
        fun onClusterItemRendered(item: T, marker: Marker)
    }
}
