package com.github.amapkit.map.overlays.clustering.algorithm

import com.amap.api.maps.model.CameraPosition
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem

class ScreenBasedAlgorithmAdapter<T : ClusterItem>(
    private val algorithm: Algorithm<T>
) : AbstractAlgorithm<T>(), ScreenBasedAlgorithm<T> {

    override fun addItem(item: T) = algorithm.addItem(item)

    override fun addItems(items: Collection<T>) = algorithm.addItems(items)

    override fun clearItems() {
        algorithm.clearItems()
    }

    override fun removeItem(item: T) = algorithm.removeItem(item)

    override fun removeItems(items: Collection<T>) = algorithm.removeItems(items)

    override fun updateItem(item: T) = algorithm.updateItem(item)

    override fun clustersAtZoom(zoom: Float): Set<Cluster<T>> = algorithm.clustersAtZoom(zoom)

    override val items: Collection<T>
        get() = algorithm.items

    override var maxDistanceBetweenClusteredItems: Int
        get() = algorithm.maxDistanceBetweenClusteredItems
        set(value) {
            algorithm.maxDistanceBetweenClusteredItems = value
        }

    override val shouldReclusterOnMapMovement = false

    override fun onCameraChange(position: CameraPosition) {
        TODO("Not yet implemented")
    }
}
