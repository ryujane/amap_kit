package com.github.amapkit.map.overlays.clustering.algorithm

import com.amap.api.maps.model.LatLng
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem
import com.github.amapkit.map.utils.Bounds
import com.github.amapkit.map.utils.Point
import com.github.amapkit.map.utils.PointQuadTree
import com.github.amapkit.map.utils.toPoint
import kotlin.math.pow

const val DEFAULT_MAX_DISTANCE_AT_ZOOM = 100

class NonHierarchicalDistanceBasedAlgorithm<T : ClusterItem> : AbstractAlgorithm<T>() {
    private val quadItems = linkedSetOf<QuadItem<T>>()

    /** All access must be synchronized because the tree is shared by render workers. */
    private val quadTree = PointQuadTree<QuadItem<T>>(0.0, 1.0, 0.0, 1.0)

    override var maxDistanceBetweenClusteredItems = DEFAULT_MAX_DISTANCE_AT_ZOOM

    override val items: Collection<T>
        get() = synchronized(quadTree) { quadItems.mapTo(linkedSetOf()) { it.clusterItem } }

    override fun addItem(item: T): Boolean = synchronized(quadTree) {
        val quadItem = QuadItem(item)
        quadItems.add(quadItem).also { added ->
            if (added) quadTree.add(quadItem)
        }
    }

    override fun addItems(items: Collection<T>): Boolean =
        items.fold(false) { changed, item -> addItem(item) || changed }

    override fun clearItems() = synchronized(quadTree) {
        quadItems.clear()
        quadTree.clear()
    }

    override fun removeItem(item: T): Boolean = synchronized(quadTree) {
        val quadItem = QuadItem(item)
        quadItems.remove(quadItem).also { removed ->
            if (removed) quadTree.remove(quadItem)
        }
    }

    override fun updateItem(item: T): Boolean = synchronized(quadTree) {
        if (!removeItem(item)) return@synchronized false
        addItem(item)
    }

    override fun removeItems(items: Collection<T>): Boolean = synchronized(quadTree) {
        items.fold(false) { changed, item -> removeItem(item) || changed }
    }

    override fun clustersAtZoom(zoom: Float): Set<Cluster<T>> {
        val zoomSpan =
            maxDistanceBetweenClusteredItems / 2.0.pow(zoom.toInt().toDouble()) / TILE_SIZE
        val visitedCandidates = mutableSetOf<QuadItem<T>>()
        val results = mutableSetOf<Cluster<T>>()
        val distanceToCluster = mutableMapOf<QuadItem<T>, Double>()
        val itemToCluster = mutableMapOf<QuadItem<T>, StaticCluster<T>>()

        synchronized(quadTree) {
            for (candidate in quadItems) {
                if (candidate in visitedCandidates) continue

                val clusterItems = quadTree.search(boundsAround(candidate.point, zoomSpan))
                if (clusterItems.size == 1) {
                    results += candidate
                    visitedCandidates += candidate
                    distanceToCluster[candidate] = 0.0
                    continue
                }

                val cluster = StaticCluster<T>(candidate.position)
                results += cluster

                for (clusterItem in clusterItems) {
                    val distance = distanceSquared(clusterItem.point, candidate.point)
                    val existingDistance = distanceToCluster[clusterItem]
                    if (existingDistance != null) {
                        if (existingDistance < distance) continue
                        itemToCluster[clusterItem]?.remove(clusterItem.clusterItem)
                    }

                    distanceToCluster[clusterItem] = distance
                    cluster.add(clusterItem.clusterItem)
                    itemToCluster[clusterItem] = cluster
                }
                visitedCandidates += clusterItems
            }
        }
        return results
    }

    private fun distanceSquared(first: Point, second: Point): Double =
        (first.x - second.x) * (first.x - second.x) +
            (first.y - second.y) * (first.y - second.y)

    private fun boundsAround(point: Point, span: Double): Bounds {
        val halfSpan = span / 2
        return Bounds(
            point.x - halfSpan,
            point.x + halfSpan,
            point.y - halfSpan,
            point.y + halfSpan
        )
    }

    class QuadItem<T : ClusterItem>(val clusterItem: T) : PointQuadTree.Item, Cluster<T> {
        override val position: LatLng = clusterItem.position
        override val point: Point = toPoint(position)
        override val items: Collection<T> = setOf(clusterItem)
        override val size = 1

        override fun hashCode() = clusterItem.hashCode()

        override fun equals(other: Any?) =
            other is QuadItem<*> && other.clusterItem == clusterItem
    }

    private companion object {
        const val TILE_SIZE = 256
    }
}
