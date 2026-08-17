package com.github.amapkit.map.overlays.clustering.algorithm

import com.amap.api.maps.model.LatLng
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem

class StaticCluster<T : ClusterItem>(
    override val position: LatLng
) : Cluster<T> {
    private val mutableItems = linkedSetOf<T>()

    fun add(item: T) = mutableItems.add(item)

    fun remove(item: T) = mutableItems.remove(item)

    override fun toString() = "StaticCluster(position=$position, items=$items, size=$size)"

    override val items: Collection<T>
        get() = mutableItems

    override val size: Int
        get() = mutableItems.size

    override fun equals(other: Any?) =
        other is StaticCluster<*> && other.position == position && other.items == items

    override fun hashCode() = position.hashCode() + items.hashCode()
}
