package com.github.amapkit.map

import android.content.Context
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.CustomMapStyleOptions
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.MyLocationStyle
import io.flutter.plugin.common.BinaryMessenger

class AmapBuilder : AMapOptionsSink {
    private val options = AMapOptions()
    private var customMapStyleOptions: CustomMapStyleOptions? = null
    private var myLocationStyle: MyLocationStyle? = null
    private var myLocationEnabled = false
    private var minZoomLevel = 3f
    private var maxZoomLevel = 20f
    private var latLngBounds: LatLngBounds? = null
    private var trafficEnabled = true
    private var touchPoiEnabled = true
    private var buildingsEnabled = true
    private var labelsEnabled = true
    private var compassEnabled = true
    private var scaleEnabled = false
    private var zoomGesturesEnabled = true
    private var scrollGesturesEnabled = true
    private var rotateGesturesEnabled = true
    private var tiltGesturesEnabled = true
    private var initialClusterManagers: List<PlatformClusterManager>? = null
    private var initialMarkers: List<PlatformMarker> = emptyList()

    private var initialPolylines: List<PlatformPolyline> = emptyList()

    private var initialPolygons: List<PlatformPolygon> = emptyList()
    private var initialCircles: List<PlatformCircle> = emptyList()
    private var initialHeatmaps: List<PlatformHeatmap> = emptyList()
    private var initialTileOverlays: List<PlatformTileOverlay> = emptyList()
    private var initialGroundOverlays: List<PlatformGroundOverlay> = emptyList()

    fun build(
        id: Int,
        context: Context,
        binaryMessenger: BinaryMessenger,
        lifecycleProvider: LifecycleProvider
    ): AmapMapController {
        return AmapMapController(
            context,
            id,
            lifecycleProvider,
            binaryMessenger,
            options
        ).apply {
            setMinMaxZoomPreference(minZoomLevel, maxZoomLevel)
            setLatLngBounds(latLngBounds)
            setTrafficEnabled(trafficEnabled)
            setTouchPoiEnabled(touchPoiEnabled)
            setBuildingsEnabled(buildingsEnabled)
            setLabelsEnabled(labelsEnabled)
            setCompassEnabled(compassEnabled)
            setScaleEnabled(scaleEnabled)
            setZoomGesturesEnabled(zoomGesturesEnabled)
            setScrollGesturesEnabled(scrollGesturesEnabled)
            setRotateGesturesEnabled(rotateGesturesEnabled)
            setTiltGesturesEnabled(tiltGesturesEnabled)
            setInitialClusterManagers(initialClusterManagers)
            setInitialMarkers(initialMarkers)
            setInitialPolygons(initialPolygons)
            setInitialPolylines(initialPolylines)
            setInitialCircles(initialCircles)
            setInitialHeatmaps(initialHeatmaps)
            setInitialTileOverlays(initialTileOverlays)
            setInitialGroundOverlays(initialGroundOverlays)
            setMyLocationStyle(myLocationStyle)
            setMyLocationEnabled(myLocationEnabled)
            setCustomMapStyleOptions(customMapStyleOptions)
        }
    }

    fun setInitialCameraPosition(camera: CameraPosition) {
        options.camera(camera)
    }

    override fun setMapType(mapType: Int) {
        options.mapType(mapType)
    }

    override fun setCustomMapStyleOptions(customMapStyleOptions: CustomMapStyleOptions?) {
        this.customMapStyleOptions = customMapStyleOptions
    }

    override fun setMyLocationStyle(myLocationStyle: MyLocationStyle?) {
        this.myLocationStyle = myLocationStyle
    }

    override fun setMyLocationEnabled(enabled: Boolean) {
        myLocationEnabled = enabled
    }

    override fun setMinMaxZoomPreference(min: Float?, max: Float?) {
        min?.let { minZoomLevel = it }
        max?.let { maxZoomLevel = it }
    }
    override fun setLatLngBounds(latLngBounds: LatLngBounds?) {
        this.latLngBounds = latLngBounds
    }

    override fun setTrafficEnabled(trafficEnabled: Boolean) {
        this.trafficEnabled = trafficEnabled
    }

    override fun setTouchPoiEnabled(touchPoiEnabled: Boolean) {
        this.touchPoiEnabled = touchPoiEnabled
    }

    override fun setBuildingsEnabled(buildingsEnabled: Boolean) {
        this.buildingsEnabled = buildingsEnabled
    }

    override fun setLabelsEnabled(labelsEnabled: Boolean) {
        this.labelsEnabled = labelsEnabled
    }

    override fun setCompassEnabled(compassEnabled: Boolean) {
        this.compassEnabled = compassEnabled
    }

    override fun setScaleEnabled(scaleEnabled: Boolean) {
        this.scaleEnabled = scaleEnabled
    }

    override fun setZoomGesturesEnabled(zoomGesturesEnabled: Boolean) {
        this.zoomGesturesEnabled = zoomGesturesEnabled
    }

    override fun setScrollGesturesEnabled(scrollGesturesEnabled: Boolean) {
        this.scrollGesturesEnabled = scrollGesturesEnabled
    }

    override fun setRotateGesturesEnabled(rotateGesturesEnabled: Boolean) {
        this.rotateGesturesEnabled = rotateGesturesEnabled
    }

    override fun setTiltGesturesEnabled(tiltGesturesEnabled: Boolean) {
        this.tiltGesturesEnabled = tiltGesturesEnabled
    }

    override fun setInitialClusterManagers(initialClusterManager: List<PlatformClusterManager>?) {
        this.initialClusterManagers = initialClusterManager
    }

    override fun setInitialMarkers(initialMarkers: List<PlatformMarker>) {
        this.initialMarkers = initialMarkers
    }

    override fun setInitialPolylines(initialPolylines: List<PlatformPolyline>) {
        this.initialPolylines = initialPolylines
    }

    override fun setInitialPolygons(initialPolygons: List<PlatformPolygon>) {
        this.initialPolygons = initialPolygons
    }

    override fun setInitialCircles(initialCircles: List<PlatformCircle>) {
        this.initialCircles = initialCircles
    }

    override fun setInitialHeatmaps(initialHeatmaps: List<PlatformHeatmap>) {
        this.initialHeatmaps = initialHeatmaps
    }

    override fun setInitialTileOverlays(initialTileOverlays: List<PlatformTileOverlay>) {
        this.initialTileOverlays = initialTileOverlays
    }

    override fun setInitialGroundOverlays(initialGroundOverlays: List<PlatformGroundOverlay>) {
        this.initialGroundOverlays = initialGroundOverlays
    }
}
