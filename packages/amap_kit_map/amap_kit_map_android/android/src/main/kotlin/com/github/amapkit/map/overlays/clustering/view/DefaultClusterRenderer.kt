package com.github.amapkit.map.overlays.clustering.view

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.TimeInterpolator
import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.graphics.drawable.LayerDrawable
import android.graphics.drawable.ShapeDrawable
import android.graphics.drawable.shapes.OvalShape
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.os.MessageQueue
import android.util.SparseArray
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import android.widget.TextView
import com.amap.api.maps.AMap
import com.amap.api.maps.Projection
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions
import com.github.amapkit.map.R
import com.github.amapkit.map.collections.MarkerManager
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem
import com.github.amapkit.map.overlays.clustering.ClusterManager
import com.github.amapkit.map.utils.Point
import com.github.amapkit.map.utils.SphericalMercatorProjection
import java.util.ArrayDeque
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock
import kotlin.math.abs
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sign

open class DefaultClusterRenderer<T : ClusterItem>(
    private val context: Context,
    private val map: AMap,
    val clusterManager: ClusterManager<T>
) : ClusterRenderer<T> {
    override var animationEnabled = true
    override var animationDurationMillis: Long = 300
    override var clusterClickListener: ClusterManager.OnClusterClickListener<T>? = null
    override var clusterInfoWindowClickListener: ClusterManager.OnClusterInfoWindowClickListener<T>? = null
    override var itemClickListener: ClusterManager.OnClusterItemClickListener<T>? = null
    override var itemInfoWindowClickListener: ClusterManager.OnClusterItemInfoWindowClickListener<T>? = null

    private val density: Float = context.resources.displayMetrics.density
    private var zoom = 0f
    @Volatile
    private var disposed = false
    protected val minClusterSize = 4
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val viewModifier = ViewModifier()
    private var coloredCircleBackground: ShapeDrawable? = null
    private val clusterBuckets = intArrayOf(10, 20, 50, 100, 200, 500, 1000)
    private var renderedMarkers = ConcurrentHashMap.newKeySet<MarkerWithPosition>()
    private val icons = SparseArray<BitmapDescriptor>()
    private val itemMarkerCache = MarkerCache<T>()
    private val clusterMarkerCache = MarkerCache<Cluster<T>>()
    private var clusters: Set<Cluster<T>> = emptySet()

    private fun makeClusterBackground(): LayerDrawable {
        coloredCircleBackground = ShapeDrawable(OvalShape())
        val outline = ShapeDrawable(OvalShape())
        outline.paint.setColor(-0x7f000001) // Transparent white.
        val background = LayerDrawable(arrayOf<Drawable?>(outline, coloredCircleBackground))
        val strokeWidth = (density * 3).toInt()
        background.setLayerInset(1, strokeWidth, strokeWidth, strokeWidth, strokeWidth)
        return background
    }

    private fun makeTextView(context: Context) = TextView(context).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT
        )
        val twelveDpi = (12 * density).toInt()
        setPadding(twelveDpi, twelveDpi, twelveDpi, twelveDpi)
    }

    protected fun clusterText(bucket: Int) =
        if (bucket < clusterBuckets.first()) bucket.toString() else "$bucket+"

    /**
     * Gets the "bucket" for a particular cluster. By default, uses the number of points within the
     * cluster, bucketed to some set points.
     */
    protected fun bucketForCluster(cluster: Cluster<T>): Int {
        if (cluster.size <= clusterBuckets.first()) return cluster.size
        for (index in 0..<clusterBuckets.lastIndex) {
            if (cluster.size < clusterBuckets[index + 1]) return clusterBuckets[index]
        }
        return clusterBuckets.last()
    }

    override fun onClustersChanged(clusters: Set<Cluster<T>>) {
        if (disposed) return
        viewModifier.queue(clusters)
    }

    override fun onAdd() {
        clusterManager.itemMarkers.markerClickListener = AMap.OnMarkerClickListener { marker ->
            val item = itemMarkerCache.get(marker)
            item != null && itemClickListener?.onClusterItemClick(item) == true
        }

        clusterManager.itemMarkers.infoWindowClickListener = AMap.OnInfoWindowClickListener { marker ->
            itemMarkerCache.get(marker)?.let { item ->
                itemInfoWindowClickListener?.onClusterItemInfoWindowClick(item)
            }
        }

        clusterManager.clusterMarkers.markerClickListener = AMap.OnMarkerClickListener { marker ->
            clusterMarkerCache.get(marker)?.let { cluster ->
                clusterClickListener?.onClusterClick(cluster)
            } == true
        }

        clusterManager.clusterMarkers.infoWindowClickListener = AMap.OnInfoWindowClickListener { marker ->
            clusterMarkerCache.get(marker)?.let { cluster ->
                clusterInfoWindowClickListener?.onClusterInfoWindowClick(cluster)
            }
        }
    }

    override fun onRemove() {
        clusterManager.itemMarkers.markerClickListener = null
        clusterManager.itemMarkers.infoWindowClickListener = null
        clusterManager.clusterMarkers.markerClickListener = null
        clusterManager.clusterMarkers.infoWindowClickListener = null
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        onRemove()
        viewModifier.removeCallbacksAndMessages(null)
        executor.shutdownNow()
    }

    override fun colorForClusterSize(clusterSize: Int): Int {
        val hueRange = 220f
        val sizeRange = 300f
        val size = min(clusterSize.toFloat(), sizeRange)
        val hue = (sizeRange - size) * (sizeRange - size) / (sizeRange * sizeRange) * hueRange
        return Color.HSVToColor(
            floatArrayOf(
                hue, 1f, .6f
            )
        )
    }

    protected fun descriptorForCluster(cluster: Cluster<T>): BitmapDescriptor {
        val bucket = bucketForCluster(cluster)
        icons[bucket]?.let { return it }

        val background = makeClusterBackground()
        coloredCircleBackground?.paint?.color = colorForClusterSize(bucket)
        val descriptor = BitmapDescriptorFactory.fromView(
            makeTextView(context).apply {
                text = clusterText(bucket)
                setTextAppearance(textAppearanceForClusterSize(cluster.size))
                this.background = background
            }
        )
        icons.put(bucket, descriptor)
        return descriptor
    }

    protected fun shouldRenderAsCluster(cluster: Cluster<T>) = cluster.size >= minClusterSize

    protected fun shouldRender(
        oldClusters: Set<Cluster<T>>,
        newClusters: Set<Cluster<T>>
    ) = newClusters != oldClusters


    override fun textAppearanceForClusterSize(clusterSize: Int) =
        R.style.ClusterIcon_TextAppearance

    private fun distanceSquared(a: Point, b: Point): Double {
        return (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
    }

    private fun findClosestCluster(markers: List<Point>?, point: Point): Point? {
        if (markers.isNullOrEmpty()) return null

        val maxDistance = clusterManager.algorithm.maxDistanceBetweenClusteredItems
        var minDistSquared = (maxDistance * maxDistance).toDouble()
        var closest: Point? = null
        for (candidate in markers) {
            val dist = distanceSquared(candidate, point)
            if (dist < minDistSquared) {
                closest = candidate
                minDistSquared = dist
            }
        }
        return closest
    }

    class MarkerCache<T> {
        private val cache = mutableMapOf<T, Marker>()
        private val reverseCache = mutableMapOf<Marker, T>()

        operator fun get(item: T): Marker? = cache[item]

        operator fun get(marker: Marker): T? = reverseCache[marker]

        fun put(item: T, marker: Marker) {
            cache[item] = marker
            reverseCache[marker] = item
        }

        fun remove(marker: Marker) {
            reverseCache.remove(marker)?.let(cache::remove)
        }
    }

    @SuppressLint("HandlerLeak")
    inner class ViewModifier : Handler(Looper.getMainLooper()) {
        private var renderInProgress = false
        private var pendingRenderTask: RenderTask? = null

        override fun handleMessage(message: Message) {
            if (disposed) return
            if (message.what == TASK_FINISHED) {
                renderInProgress = false
                if (pendingRenderTask != null) sendEmptyMessage(RUN_TASK)
                return
            }
            removeMessages(RUN_TASK)
            if (renderInProgress) return

            val renderTask = synchronized(this) {
                pendingRenderTask?.also { renderInProgress = true }
            } ?: return
            synchronized(this) {
                pendingRenderTask = null
            }

            renderTask.onComplete = { sendEmptyMessage(TASK_FINISHED) }
            renderTask.projection = map.projection
            renderTask.setMapZoom(map.cameraPosition.zoom)
            executor.execute(renderTask)
        }

        fun queue(clusters: Set<Cluster<T>>) {
            if (disposed) return
            synchronized(this) {
                // Overwrite any pending cluster tasks - we don't care about intermediate states.
                pendingRenderTask = RenderTask(clusters)
            }
            sendEmptyMessage(RUN_TASK)
        }

    }

    inner class RenderTask(private val clusters: Set<Cluster<T>>) : Runnable {
        var onComplete: (() -> Unit)? = null
        lateinit var projection: Projection
        private var mapZoom = 0f
        private lateinit var sphericalProjection: SphericalMercatorProjection

        fun setMapZoom(zoom: Float) {
            mapZoom = zoom
            sphericalProjection = SphericalMercatorProjection(
                TILE_SIZE * 2.0.pow(min(zoom, this@DefaultClusterRenderer.zoom).toDouble())
            )
        }

        override fun run() {
            if (disposed) {
                onComplete?.invoke()
                return
            }
            if (!shouldRender(
                    this@DefaultClusterRenderer.clusters.toSet(),
                    clusters.toSet()
                )
            ) {
                onComplete?.invoke()
                return
            }
            val markerModifier = MarkerModifier()

            val currentZoom = mapZoom
            val zoomingIn = currentZoom > this@DefaultClusterRenderer.zoom
            val zoomDelta = currentZoom - this@DefaultClusterRenderer.zoom
            val markersToRemove = renderedMarkers
            // Prevent crashes: https://issuetracker.google.com/issues/35827242
            val visibleBounds = runCatching { projection.visibleRegion.latLngBounds }
                .getOrElse {
                    LatLngBounds.builder().include(LatLng(0.0, 0.0)).build()
                }

            val existingClustersOnScreen =
                if (this@DefaultClusterRenderer.clusters.isNotEmpty() && animationEnabled) {
                    this@DefaultClusterRenderer.clusters.mapNotNull { cluster ->
                        cluster.takeIf {
                            shouldRenderAsCluster(it) && visibleBounds.contains(it.position)
                        }?.let { sphericalProjection.toPoint(it.position) }
                    }
                } else null

            val newMarkers = ConcurrentHashMap.newKeySet<MarkerWithPosition>()
            for (cluster in clusters) {
                val onScreen = visibleBounds.contains(cluster.position)
                if (zoomingIn && onScreen && animationEnabled) {
                    val point = sphericalProjection.toPoint(cluster.position)
                    val closest = findClosestCluster(existingClustersOnScreen, point)
                    if (closest != null) {
                        val animateTo = sphericalProjection.toLatLng(closest)
                        markerModifier.add(true, CreateMarkerTask(cluster, newMarkers, animateTo))
                    } else {
                        markerModifier.add(true, CreateMarkerTask(cluster, newMarkers, null))
                    }
                } else {
                    markerModifier.add(onScreen, CreateMarkerTask(cluster, newMarkers, null))
                }
            }

            markerModifier.waitUntilFree()
            markersToRemove.removeAll(newMarkers)

            val newClustersOnScreen = if (animationEnabled) {
                clusters.mapNotNull { cluster ->
                    cluster.takeIf {
                        shouldRenderAsCluster(it) && visibleBounds.contains(it.position)
                    }?.let { sphericalProjection.toPoint(it.position) }
                }
            } else null

            for (marker in markersToRemove) {
                val onScreen = visibleBounds.contains(marker.position)
                if (!zoomingIn && zoomDelta > -3 && onScreen && animationEnabled) {
                    val point = sphericalProjection.toPoint(marker.position)
                    val closest = findClosestCluster(newClustersOnScreen, point)
                    if (closest != null) {
                        val animateTo = sphericalProjection.toLatLng(closest)
                        markerModifier.animateThenRemove(marker, marker.position, animateTo)
                    } else {
                        markerModifier.remove(true, marker.marker)
                    }
                } else {
                    markerModifier.remove(onScreen, marker.marker)
                }
            }

            markerModifier.waitUntilFree()

            renderedMarkers = newMarkers
            this@DefaultClusterRenderer.clusters = clusters
            this@DefaultClusterRenderer.zoom = currentZoom
            onComplete?.invoke()
        }
    }

    @SuppressLint("HandlerLeak")
    inner class MarkerModifier : Handler(Looper.getMainLooper()), MessageQueue.IdleHandler {
        private val lock = ReentrantLock()
        private val busyCondition = lock.newCondition()
        private val createMarkerTasks = ArrayDeque<CreateMarkerTask>()
        private val onScreenCreateMarkerTasks = ArrayDeque<CreateMarkerTask>()
        private val removeMarkerTasks = ArrayDeque<Marker>()
        private val onScreenRemoveMarkerTasks = ArrayDeque<Marker>()
        private val animationTasks = ArrayDeque<AnimationTask>()
        private var idleListenerAdded = false

        fun add(priority: Boolean, task: CreateMarkerTask) {
            sendEmptyMessage(BLANK)
            lock.withLock {
                if (priority) onScreenCreateMarkerTasks.add(task) else createMarkerTasks.add(task)
            }
        }

        fun remove(priority: Boolean, marker: Marker) {
            sendEmptyMessage(BLANK)
            lock.withLock {
                if (priority) onScreenRemoveMarkerTasks.add(marker) else removeMarkerTasks.add(marker)
            }
        }

        fun animate(marker: MarkerWithPosition, from: LatLng, to: LatLng) {
            lock.withLock { animationTasks.add(AnimationTask(marker, from, to)) }
        }

        fun animateThenRemove(marker: MarkerWithPosition, from: LatLng, to: LatLng) {
            lock.withLock {
                animationTasks.add(
                    AnimationTask(marker, from, to).apply {
                        removeOnAnimationComplete(clusterManager.markerManager)
                    }
                )
            }
        }

        override fun handleMessage(message: Message) {
            if (!idleListenerAdded) {
                Looper.myQueue().addIdleHandler(this)
                idleListenerAdded = true
            }
            removeMessages(BLANK)
            lock.withLock {
                repeat(TASKS_PER_BATCH) { performNextTask() }
                if (!isBusy()) {
                    idleListenerAdded = false
                    Looper.myQueue().removeIdleHandler(this)
                    busyCondition.signalAll()
                } else {
                    sendEmptyMessageDelayed(BLANK, RETRY_DELAY_MS)
                }
            }
        }

        private fun performNextTask() {
            when {
                onScreenRemoveMarkerTasks.isNotEmpty() ->
                    removeMarker(onScreenRemoveMarkerTasks.removeFirst())
                animationTasks.isNotEmpty() -> animationTasks.removeFirst().perform()
                onScreenCreateMarkerTasks.isNotEmpty() ->
                    onScreenCreateMarkerTasks.removeFirst().perform(this)
                createMarkerTasks.isNotEmpty() -> createMarkerTasks.removeFirst().perform(this)
                removeMarkerTasks.isNotEmpty() -> removeMarker(removeMarkerTasks.removeFirst())
            }
        }

        private fun isBusy() = lock.withLock {
            createMarkerTasks.isNotEmpty() ||
                onScreenCreateMarkerTasks.isNotEmpty() ||
                onScreenRemoveMarkerTasks.isNotEmpty() ||
                removeMarkerTasks.isNotEmpty() ||
                animationTasks.isNotEmpty()
        }

        fun waitUntilFree() {
            while (isBusy()) {
                sendEmptyMessage(BLANK)
                lock.withLock {
                    try {
                        if (isBusy()) busyCondition.await()
                    } catch (exception: InterruptedException) {
                        Thread.currentThread().interrupt()
                        throw IllegalStateException("Interrupted while rendering clusters", exception)
                    }
                }
            }
        }

        private fun removeMarker(marker: Marker) {
            itemMarkerCache.remove(marker)
            clusterMarkerCache.remove(marker)
            clusterManager.markerManager.remove(marker)
        }

        override fun queueIdle() = true.also {
            sendEmptyMessage(BLANK)
        }
    }

    inner class CreateMarkerTask(
        private val cluster: Cluster<T>,
        private val markersAdded: MutableSet<MarkerWithPosition>,
        private val animateFrom: LatLng?
    ) {

        fun perform(markerModifier: MarkerModifier) {
            // Don't show small clusters. Render the markers inside, instead.
            if (!shouldRenderAsCluster(cluster)) {
                for (item in cluster.items) {
                    val existingMarker = itemMarkerCache[item]
                    val markerWithPosition = if (existingMarker == null) {
                        val markerOptions = MarkerOptions()
                        if (animateFrom != null) {
                            markerOptions.position(animateFrom)
                        } else {
                            markerOptions.position(item.position)
                            item.zIndex?.let(markerOptions::zIndex)
                        }
                        onBeforeClusterItemRendered(item, markerOptions)
                        val marker = clusterManager.markerManager.addMarker(markerOptions)
                        itemMarkerCache.put(item, marker)
                        MarkerWithPosition(marker).also { markerWithPosition ->
                            animateFrom?.let {
                                markerModifier.animate(markerWithPosition, it, item.position)
                            }
                        }
                    } else {
                        onClusterItemUpdated(item, existingMarker)
                        MarkerWithPosition(existingMarker)
                    }
                    onClusterItemRendered(item, markerWithPosition.marker)
                    markersAdded += markerWithPosition
                }
                return
            }

            val existingMarker = clusterMarkerCache[cluster]
            val markerWithPosition = if (existingMarker == null) {
                val markerOptions = MarkerOptions().position(animateFrom ?: cluster.position)
                onBeforeClusterRendered(cluster, markerOptions)
                val marker = clusterManager.clusterMarkers.addMarker(markerOptions)
                clusterMarkerCache.put(cluster, marker)
                MarkerWithPosition(marker).also { markerWithPosition ->
                    animateFrom?.let {
                        markerModifier.animate(markerWithPosition, it, cluster.position)
                    }
                }
            } else {
                onClusterUpdated(cluster, existingMarker)
                MarkerWithPosition(existingMarker)
            }
            onClusterRendered(cluster, markerWithPosition.marker)
            markersAdded += markerWithPosition
        }
    }
    /**
     * A Marker and its position. [Marker.getPosition] must be called from the UI thread, so this
     * object allows lookup from other threads.
     */
    class MarkerWithPosition(val marker: Marker) {
        var position: LatLng = marker.position

        override fun equals(other: Any?) = other is MarkerWithPosition && marker == other.marker

        override fun hashCode() = marker.hashCode()
    }

    private val animationInterpolator: TimeInterpolator = DecelerateInterpolator()

    inner class AnimationTask(
        private val markerWithPosition: MarkerWithPosition,
        private val from: LatLng,
        private val to: LatLng
    ) : AnimatorListenerAdapter(), ValueAnimator.AnimatorUpdateListener {
        private val marker: Marker = markerWithPosition.marker
        private var removeOnComplete = false
        private var removalMarkerManager: MarkerManager? = null

        fun perform() {
            val valueAnimator = ValueAnimator.ofFloat(0.0f, 1.0f)
            valueAnimator.interpolator = animationInterpolator
            valueAnimator.duration = animationDurationMillis
            valueAnimator.addUpdateListener(this)
            valueAnimator.addListener(this)
            valueAnimator.start()
        }

        fun removeOnAnimationComplete(markerManager: MarkerManager) {
            removalMarkerManager = markerManager
            removeOnComplete = true
        }

        override fun onAnimationEnd(animation: Animator) {
            if (removeOnComplete) {
                itemMarkerCache.remove(marker)
                clusterMarkerCache.remove(marker)
                removalMarkerManager?.remove(marker)
            }
            markerWithPosition.position = to
        }

        override fun onAnimationUpdate(valueAnimator: ValueAnimator) {

            val fraction = valueAnimator.animatedFraction
            val lat = (to.latitude - from.latitude) * fraction + from.latitude
            var lngDelta = to.longitude - from.longitude

            // Take the shortest path across the 180th meridian.
            if (abs(lngDelta) > 180) {
                lngDelta -= sign(lngDelta) * 360
            }
            val lng = lngDelta * fraction + from.longitude
            val position = LatLng(lat, lng)
            marker.position = position
        }
    }

    /**
     * Called when a cached marker for a ClusterItem already exists on the map so the marker may
     * be updated to the latest item values. Default implementation updates the title and snippet
     * of the marker if they have changed and refreshes the info window of the marker if it is open.
     * Note that the contents of the item may not have changed since the cached marker was created -
     * implementations of this method are responsible for checking if something changed (if that
     * matters to the implementation).
     *
     *
     * The first time [ClusterManager.cluster] is invoked on a set of items
     * [.onBeforeClusterItemRendered] will be called and
     * [.onClusterItemUpdated] will not be called.
     * If an item is removed and re-added (or updated) and [ClusterManager.cluster] is
     * invoked again, then [.onClusterItemUpdated] will be called and
     * [.onBeforeClusterItemRendered] will not be called.
     *
     * @param item   item being updated
     * @param marker cached marker that contains a potentially previous state of the item.
     */
    protected fun onClusterItemUpdated(item: T, marker: Marker) {
        var changed = false
        val title = item.title
        val snippet = item.snippet
        when {
            title != null && snippet != null -> {
                if (title != marker.title) {
                    marker.title = title
                    changed = true
                }
                if (snippet != marker.snippet) {
                    marker.snippet = snippet
                    changed = true
                }
            }
            snippet != null && snippet != marker.title -> {
                marker.title = snippet
                changed = true
            }
            title != null && title != marker.title -> {
                marker.title = title
                changed = true
            }
        }

        if (marker.position != item.position) {
            marker.position = item.position
            item.zIndex?.let { marker.zIndex = it }
            changed = true
        }
        if (changed && marker.isInfoWindowShown) {
            marker.showInfoWindow()
        }
    }

    /**
     * Called before the marker for a ClusterItem is added to the map. The default implementation
     * sets the marker and snippet text based on the respective item text if they are both
     * available, otherwise it will set the title if available, and if not it will set the marker
     * title to the item snippet text if that is available.
     *
     *
     * The first time [ClusterManager.cluster] is invoked on a set of items
     * [.onBeforeClusterItemRendered] will be called and
     * [.onClusterItemUpdated] will not be called.
     * If an item is removed and re-added (or updated) and [ClusterManager.cluster] is
     * invoked again, then [.onClusterItemUpdated] will be called and
     * [.onBeforeClusterItemRendered] will not be called.
     *
     * @param item          item to be rendered
     * @param markerOptions the markerOptions representing the provided item
     */
    open fun onBeforeClusterItemRendered(item: T, markerOptions: MarkerOptions) {
        val title = item.title
        val snippet = item.snippet
        when {
            title != null && snippet != null -> markerOptions.title(title).snippet(snippet)
            title != null -> markerOptions.title(title)
            snippet != null -> markerOptions.title(snippet)
        }
        item.zIndex?.let(markerOptions::zIndex)
    }

    open fun onClusterItemRendered(clusterItem: T, marker: Marker) {

    }

    protected fun onClusterRendered(cluster: Cluster<T>, marker: Marker) {
    }

    protected fun onClusterUpdated(cluster: Cluster<T>, marker: Marker) {
        // TODO: consider adding anchor(.5, .5) (Individual markers will overlap more often)
        marker.setIcon(descriptorForCluster(cluster))
    }


    /**
     * Called before the marker for a Cluster is added to the map.
     * The default implementation draws a circle with a rough count of the number of items.
     *
     *
     * The first time [ClusterManager.cluster] is invoked on a set of items
     * [.onBeforeClusterRendered] will be called and
     * [.onClusterUpdated] will not be called. If an item is removed and
     * re-added (or updated) and [ClusterManager.cluster] is invoked
     * again, then [.onClusterUpdated] will be called and
     * [.onBeforeClusterRendered] will not be called.
     *
     * @param cluster       cluster to be rendered
     * @param markerOptions markerOptions representing the provided cluster
     */
    protected fun onBeforeClusterRendered(cluster: Cluster<T>, markerOptions: MarkerOptions) {
        // TODO: consider adding anchor(.5, .5) (Individual markers will overlap more often)
        markerOptions.icon(descriptorForCluster(cluster))
        cluster.items.firstOrNull()?.zIndex?.let(markerOptions::zIndex)
    }

    private companion object {
        const val TILE_SIZE = 256
        const val RUN_TASK = 0
        const val TASK_FINISHED = 1
        const val BLANK = 0
        const val TASKS_PER_BATCH = 10
        const val RETRY_DELAY_MS = 10L
    }
}
