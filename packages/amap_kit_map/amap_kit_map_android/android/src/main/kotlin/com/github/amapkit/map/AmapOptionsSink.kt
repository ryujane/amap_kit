package com.github.amapkit.map

import com.amap.api.maps.model.CustomMapStyleOptions
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.MyLocationStyle
import com.github.amapkit.map.overlays.clustering.ClusterManager

interface AMapOptionsSink {

    fun setMapType(mapType: Int)

    fun setCustomMapStyleOptions(customMapStyleOptions: CustomMapStyleOptions?)

    fun setMyLocationStyle(myLocationStyle: MyLocationStyle?)

    fun setMyLocationEnabled(enabled: Boolean)
    fun setMinMaxZoomPreference(min: Float?, max: Float?)

    fun setLatLngBounds(latLngBounds: LatLngBounds?)

    fun setTrafficEnabled(trafficEnabled: Boolean)

    fun setTouchPoiEnabled(touchPoiEnabled: Boolean)

    fun setBuildingsEnabled(buildingsEnabled: Boolean)

    fun setLabelsEnabled(labelsEnabled: Boolean)

    fun setCompassEnabled(compassEnabled: Boolean)

    fun setScaleEnabled(scaleEnabled: Boolean)

    fun setZoomGesturesEnabled(zoomGesturesEnabled: Boolean)

    fun setScrollGesturesEnabled(scrollGesturesEnabled: Boolean)

    fun setRotateGesturesEnabled(rotateGesturesEnabled: Boolean)

    fun setTiltGesturesEnabled(tiltGesturesEnabled: Boolean)

    fun setInitialClusterManagers(initialClusterManager: List<PlatformClusterManager>?)

    fun setInitialMarkers(initialMarkers: List<PlatformMarker>)

    fun setInitialPolylines(initialPolylines: List<PlatformPolyline>)

    fun setInitialPolygons(initialPolygons: List<PlatformPolygon>)

    fun setInitialCircles(initialCircles:  List<PlatformCircle>)

    fun setInitialHeatmaps(initialHeatmaps: List<PlatformHeatmap>)

    fun setInitialTileOverlays(initialTileOverlays: List<PlatformTileOverlay>)

    fun setInitialGroundOverlays(initialGroundOverlays: List<PlatformGroundOverlay>)
}
