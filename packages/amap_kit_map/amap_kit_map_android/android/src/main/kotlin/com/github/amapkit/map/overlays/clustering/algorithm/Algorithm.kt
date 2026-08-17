package com.github.amapkit.map.overlays.clustering.algorithm

import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem

interface Algorithm<T : ClusterItem> {
    /**
     * Adds an item to the algorithm
     * @param item the item to be added
     * @return true if the algorithm contents changed as a result of the call
     */
    fun addItem(item: T): Boolean

    /**
     * Adds a collection of items to the algorithm
     * @param items the items to be added
     * @return true if the algorithm contents changed as a result of the call
     */
    fun addItems(items: Collection<T>): Boolean

    fun clearItems()

    /**
     * Removes an item from the algorithm
     * @param item the item to be removed
     * @return true if this algorithm contained the specified element (or equivalently, if this
     * algorithm changed as a result of the call).
     */
    fun removeItem(item: T): Boolean

    /**
     * Updates the provided item in the algorithm
     * @param item the item to be updated
     * @return true if the item existed in the algorithm and was updated, or false if the item did
     * not exist in the algorithm and the algorithm contents remain unchanged.
     */
    fun updateItem(item: T): Boolean

    /**
     * Removes a collection of items from the algorithm
     * @param items the items to be removed
     * @return true if this algorithm contents changed as a result of the call
     */
    fun removeItems(items: Collection<T>): Boolean

    fun clustersAtZoom(zoom: Float): Set<Cluster<T>>

    val items: Collection<T>

    var maxDistanceBetweenClusteredItems: Int

    fun lock()

    fun unlock()
}
