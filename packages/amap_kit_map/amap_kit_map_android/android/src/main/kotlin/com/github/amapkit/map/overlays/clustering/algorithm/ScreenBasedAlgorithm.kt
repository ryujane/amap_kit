package com.github.amapkit.map.overlays.clustering.algorithm

import com.amap.api.maps.model.CameraPosition
import com.github.amapkit.map.overlays.clustering.ClusterItem

interface ScreenBasedAlgorithm<T : ClusterItem> : Algorithm<T> {

    val shouldReclusterOnMapMovement: Boolean

    fun onCameraChange(position: CameraPosition)
}
