package com.github.amapkit.map.overlays.clustering.algorithm

import androidx.collection.LruCache
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.locks.ReentrantReadWriteLock
import kotlin.concurrent.read
import kotlin.concurrent.write

class PreCachingAlgorithmDecorator<T : ClusterItem>(
    private val algorithm: Algorithm<T>
) : AbstractAlgorithm<T>() {
    private val cache = LruCache<Int, Set<Cluster<T>>>(CACHE_SIZE)
    private val cacheLock = ReentrantReadWriteLock()
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val inFlightZooms = ConcurrentHashMap.newKeySet<Int>()

    override fun addItem(item: T): Boolean =
        algorithm.addItem(item).also { changed ->
            if (changed) clearCache()
        }

    override fun addItems(items: Collection<T>): Boolean =
        algorithm.addItems(items).also { changed ->
            if (changed) clearCache()
        }

    override fun clearItems() {
        algorithm.clearItems()
        clearCache()
    }

    override fun removeItem(item: T): Boolean =
        algorithm.removeItem(item).also { changed ->
            if (changed) clearCache()
        }

    override fun updateItem(item: T): Boolean =
        algorithm.updateItem(item).also { changed ->
            if (changed) clearCache()
        }

    override fun removeItems(items: Collection<T>): Boolean =
        algorithm.removeItems(items).also { changed ->
            if (changed) clearCache()
        }

    override fun clustersAtZoom(zoom: Float): Set<Cluster<T>> {
        val discreteZoom = zoom.toInt()
        return clustersAtDiscreteZoom(discreteZoom).also {
            precache(discreteZoom + 1)
            precache(discreteZoom - 1)
        }
    }

    override val items: Collection<T>
        get() = algorithm.items

    override var maxDistanceBetweenClusteredItems: Int
        get() = algorithm.maxDistanceBetweenClusteredItems
        set(value) {
            algorithm.maxDistanceBetweenClusteredItems = value
            clearCache()
        }

    fun dispose() {
        inFlightZooms.clear()
        clearCache()
        executor.shutdownNow()
    }

    private fun precache(zoom: Int) {
        if (cache[zoom] != null || !inFlightZooms.add(zoom) || executor.isShutdown) return

        executor.execute {
            try {
                Thread.sleep((Math.random() * PRE_CACHE_DELAY_RANGE_MS + PRE_CACHE_DELAY_MIN_MS).toLong())
                clustersAtDiscreteZoom(zoom)
            } catch (_: InterruptedException) {
                Thread.currentThread().interrupt()
            } finally {
                inFlightZooms.remove(zoom)
            }
        }
    }

    private fun clearCache() = cache.evictAll()

    private fun clustersAtDiscreteZoom(discreteZoom: Int): Set<Cluster<T>> =
        cacheLock.read { cache[discreteZoom] }
            ?: cacheLock.write {
                cache[discreteZoom] ?: algorithm.clustersAtZoom(discreteZoom.toFloat()).also {
                    cache.put(discreteZoom, it)
                }
            }

    private companion object {
        const val CACHE_SIZE = 5
        const val PRE_CACHE_DELAY_MIN_MS = 500
        const val PRE_CACHE_DELAY_RANGE_MS = 500
    }
}
