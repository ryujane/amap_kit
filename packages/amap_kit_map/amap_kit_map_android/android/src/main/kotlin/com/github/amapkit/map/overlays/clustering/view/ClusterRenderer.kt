package com.github.amapkit.map.overlays.clustering.view

import androidx.annotation.StyleRes
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.clustering.ClusterItem
import com.github.amapkit.map.overlays.clustering.ClusterManager

interface ClusterRenderer<T : ClusterItem> {
    var clusterClickListener: ClusterManager.OnClusterClickListener<T>?
    var clusterInfoWindowClickListener: ClusterManager.OnClusterInfoWindowClickListener<T>?
    var itemClickListener: ClusterManager.OnClusterItemClickListener<T>?
    var itemInfoWindowClickListener: ClusterManager.OnClusterItemInfoWindowClickListener<T>?
    var animationEnabled: Boolean
    var animationDurationMillis: Long

    /**
     * Called when the view needs to be updated because new clusters need to be displayed.
     *
     * @param clusters the clusters to be displayed.
     */
    fun onClustersChanged(clusters: Set<Cluster<T>>)

    /**
     * Called when the view is added.
     */
    fun onAdd()

    /**
     * Called when the view is removed.
     */
    fun onRemove()

    /** Cancels queued rendering work and releases renderer-owned resources. */
    fun dispose()

    /**
     * Called to determine the color of a Cluster.
     */
    fun colorForClusterSize(clusterSize: Int): Int

    @StyleRes
    fun textAppearanceForClusterSize(clusterSize: Int): Int
}
