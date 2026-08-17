package com.github.amapkit.map.overlays.clustering

import android.content.Context
import android.util.Log
import com.amap.api.maps.AMap
import com.amap.api.maps.model.Marker
import com.github.amapkit.map.collections.MarkerCollection
import com.github.amapkit.map.collections.MarkerManager
import com.github.amapkit.map.overlays.clustering.algorithm.Algorithm
import com.github.amapkit.map.overlays.clustering.algorithm.NonHierarchicalDistanceBasedAlgorithm
import com.github.amapkit.map.overlays.clustering.algorithm.PreCachingAlgorithmDecorator
import com.github.amapkit.map.overlays.clustering.algorithm.ScreenBasedAlgorithm
import com.github.amapkit.map.overlays.clustering.algorithm.ScreenBasedAlgorithmAdapter
import com.github.amapkit.map.overlays.clustering.view.ClusterRenderer
import com.github.amapkit.map.overlays.clustering.view.DefaultClusterRenderer
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class ClusterManager<T : ClusterItem>(
    context: Context,
    private val map: AMap,
    internal val markerManager: MarkerManager
) : AMap.OnMarkerClickListener, AMap.OnInfoWindowClickListener {
    internal val itemMarkers: MarkerCollection = markerManager.createCollection()
    internal val clusterMarkers: MarkerCollection = markerManager.createCollection()

    private val preCachingAlgorithm =
        PreCachingAlgorithmDecorator<T>(NonHierarchicalDistanceBasedAlgorithm())
    internal val algorithm: ScreenBasedAlgorithm<T> =
        ScreenBasedAlgorithmAdapter(preCachingAlgorithm)
    private var renderer: ClusterRenderer<T> = DefaultClusterRenderer(context, map, this)
    private val taskLock = ReentrantLock()
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var clusteringJob: Job? = null

    var clusterClickListener: OnClusterClickListener<T>? = null
        set(value) {
            field = value
            renderer.clusterClickListener = value
        }
    var clusterInfoWindowClickListener: OnClusterInfoWindowClickListener<T>? = null
        set(value) {
            field = value
            renderer.clusterInfoWindowClickListener = value
        }
    var clusterItemClickListener: OnClusterItemClickListener<T>? = null
        set(value) {
            field = value
            renderer.itemClickListener = value
        }
    var clusterItemInfoWindowClickListener: OnClusterItemInfoWindowClickListener<T>? = null
        set(value) {
            field = value
            renderer.itemInfoWindowClickListener = value
        }
    var animationEnabled: Boolean
        get() = renderer.animationEnabled
        set(value) {
            renderer.animationEnabled = value
        }

    @Volatile
    private var disposed = false

    init {
        renderer.onAdd()
    }

    fun addItem(item: T) = withAlgorithmLock { addItem(item) }

    fun addItems(items: Collection<T>) = withAlgorithmLock { addItems(items) }

    fun updateItem(item: T) = withAlgorithmLock { updateItem(item) }

    fun removeItem(item: T) = withAlgorithmLock { removeItem(item) }

    fun removeItems(items: Collection<T>) = withAlgorithmLock { removeItems(items) }

    fun clearItems() = withAlgorithmLock { clearItems() }

    fun cluster() {
        if (disposed) return

        taskLock.withLock {
            val zoom = map.cameraPosition.zoom
            clusteringJob?.cancel()
            clusteringJob = coroutineScope.launch {
                val clusters = try {
                    withAlgorithmLock { clustersAtZoom(zoom) }
                } catch (exception: CancellationException) {
                    throw exception
                } catch (exception: Exception) {
                    Log.e(TAG, "Cluster calculation failed", exception)
                    return@launch
                }

                ensureActive()
                withContext(Dispatchers.Main.immediate) {
                    if (!disposed) renderer.onClustersChanged(clusters)
                }
            }
        }
    }

    fun setRenderer(newRenderer: ClusterRenderer<T>) {
        renderer.clusterClickListener = null
        renderer.itemClickListener = null
        clusterMarkers.clear()
        itemMarkers.clear()
        renderer.dispose()

        renderer = newRenderer.apply {
            onAdd()
            this.clusterClickListener = this@ClusterManager.clusterClickListener
            this.clusterInfoWindowClickListener = this@ClusterManager.clusterInfoWindowClickListener
            this.itemClickListener = this@ClusterManager.clusterItemClickListener
            this.itemInfoWindowClickListener =
                this@ClusterManager.clusterItemInfoWindowClickListener
        }
        cluster()
    }

    override fun onMarkerClick(marker: Marker) = markerManager.onMarkerClick(marker)

    override fun onInfoWindowClick(marker: Marker) = markerManager.onInfoWindowClick(marker)

    fun dispose() {
        if (disposed) return
        disposed = true
        clusteringJob?.cancel()
        coroutineScope.cancel()
        preCachingAlgorithm.dispose()
        renderer.dispose()
        itemMarkers.clear()
        clusterMarkers.clear()
    }

    private inline fun <R> withAlgorithmLock(block: Algorithm<T>.() -> R): R {
        algorithm.lock()
        return try {
            algorithm.block()
        } finally {
            algorithm.unlock()
        }
    }

    fun interface OnClusterClickListener<T : ClusterItem> {
        fun onClusterClick(cluster: Cluster<T>): Boolean
    }

    fun interface OnClusterInfoWindowClickListener<T : ClusterItem> {
        fun onClusterInfoWindowClick(cluster: Cluster<T>)
    }

    fun interface OnClusterItemClickListener<T : ClusterItem> {
        fun onClusterItemClick(item: T): Boolean
    }

    fun interface OnClusterItemInfoWindowClickListener<T : ClusterItem> {
        fun onClusterItemInfoWindowClick(item: T)
    }

    private companion object {
        const val TAG = "ClusterManager"
    }
}
