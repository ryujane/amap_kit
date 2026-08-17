package com.github.amapkit.map.overlays.clustering

import com.amap.api.maps.model.LatLng

interface ClusterItem {
    /**
     * The position of this marker. This must always return the same value.
     */
    val position: LatLng

    /**
     * The title of this marker.
     */
    val title: String?

    /**
     * The description of this marker.
     */
    val snippet: String?

    /**
     * The z-index of this marker.
     */
    val zIndex: Float?
}
