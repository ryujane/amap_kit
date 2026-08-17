package com.github.amapkit.map

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.location.Location
import android.os.Bundle
import android.view.View
import androidx.annotation.VisibleForTesting
import androidx.core.content.ContextCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.amap.api.maps.AMap
import com.amap.api.maps.AMap.OnMapLoadedListener
import com.amap.api.maps.AMapOptions
import com.amap.api.maps.CameraUpdate
import com.amap.api.maps.MapView
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.CustomMapStyleOptions
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.MyLocationStyle
import com.github.amapkit.map.collections.MarkerManager
import com.github.amapkit.map.overlays.circle.CirclesController
import com.github.amapkit.map.overlays.clustering.ClusterManagersController
import com.github.amapkit.map.overlays.heatmap.HeatmapsController
import com.github.amapkit.map.overlays.ground.GroundOverlaysController
import com.github.amapkit.map.overlays.marker.MarkersController
import com.github.amapkit.map.overlays.polygon.PolygonsController
import com.github.amapkit.map.overlays.polyline.PolylinesController
import com.github.amapkit.map.overlays.tile.TileOverlaysController
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding.OnSaveInstanceStateListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream

class AmapMapController(
    private val context: Context,
    internal val id: Int,
    lifecycleProvider: LifecycleProvider,
    private val binaryMessenger: BinaryMessenger,
    options: AMapOptions
) : PlatformView, DefaultLifecycleObserver, MapsApi, OnMapLoadedListener,
    AMapOptionsSink, AmapMapListener, OnSaveInstanceStateListener, AMap.OnMyLocationChangeListener {
    private val mapView = MapView(context, options)
    private val map = mapView.map
    private val flutterApi = MapsCallbackApi(binaryMessenger, id.toString())
    private val assetManager = context.assets
    @VisibleForTesting
    private val density = context.resources.displayMetrics.density
    private val markerManager = MarkerManager(map)
    private val clusterManagersController =
        ClusterManagersController(context, flutterApi, map, markerManager)
    private val markersController = MarkersController(
        flutterApi,
        density,
        assetManager,
        Convert.BitmapDescriptorFactoryWrapper(),
        clusterManagersController,
        markerManager
    )
    private val polylinesController = PolylinesController(map, flutterApi, density, assetManager)
    private val polygonsController = PolygonsController(map)
    private val circlesController = CirclesController(map)
    private val heatmapsController = HeatmapsController(map)
    private val tileOverlaysController = TileOverlaysController(map, flutterApi)
    private val groundOverlaysController = GroundOverlaysController(
        map,
        assetManager,
        density,
        Convert.BitmapDescriptorFactoryWrapper()
    )
    private val lifecycle = lifecycleProvider.currentLifecycle()

    private var disposed = false
    private var mapLoaded = false
    private var mapReadyCallback: ((Result<Unit>) -> Unit)? = null

    init {
        map.setOnMapLoadedListener(this)
        map.setOnMapClickListener(this)
        map.setOnCameraChangeListener(this)
        map.setOnMapLongClickListener(this)
        MapsApi.setUp(binaryMessenger, this, id.toString())
        lifecycle?.addObserver(this)
    }

    override fun getView(): View = mapView

    override fun dispose() {
        if (disposed) return
        disposed = true
        mapReadyCallback?.invoke(
            Result.failure(FlutterError("map_disposed", "Map $id was disposed before it became ready."))
        )
        mapReadyCallback = null
        clusterManagersController.dispose()
        markersController.dispose()
        markerManager.dispose()
        polylinesController.dispose()
        polygonsController.dispose()
        circlesController.dispose()
        heatmapsController.dispose()
        tileOverlaysController.dispose()
        groundOverlaysController.dispose()
        map.setOnMapLoadedListener(null)
        map.setOnMapClickListener(null)
        map.setOnCameraChangeListener(null)
        map.setOnMapLongClickListener(null)
        map.setOnMyLocationChangeListener(null)
        map.isMyLocationEnabled = false
        mapView.onDestroy()
        MapsApi.setUp(binaryMessenger, null, id.toString())
        lifecycle?.removeObserver(this)
    }

    // DefaultLifecycleObserver

    override fun onCreate(owner: LifecycleOwner) {
        if (disposed) return
        mapView.onCreate(null)
    }

    override fun onResume(owner: LifecycleOwner) {
        if (disposed) return
        mapView.onResume()
    }

    override fun onPause(owner: LifecycleOwner) {
        if (disposed) return
        mapView.onPause()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        owner.lifecycle.removeObserver(this)
        dispose()
    }

    override fun waitForMap(callback: (Result<Unit>) -> Unit) {
        if (disposed) {
            callback(Result.failure(FlutterError("map_disposed", "Map $id has been disposed.")))
        } else if (!mapLoaded) {
            mapReadyCallback = callback
        } else {
            callback(Result.success(Unit))
        }
    }

    override fun updateMapOptions(options: PlatformMapOptions) {
        Convert.interpretMapConfiguration(
            options,
            this,
            assetManager,
            density,
            Convert.BitmapDescriptorFactoryWrapper()
        )
    }

    override fun moveCamera(update: PlatformCameraUpdate) {
        map.moveCamera(Convert.cameraUpdateFromPigeon(update, density))
    }

    override fun animateCamera(
        update: PlatformCameraUpdate,
        durationMillis: Long?
    ) {
        val cameraUpdate: CameraUpdate = Convert.cameraUpdateFromPigeon(update, density)
        if (durationMillis != null) {
            map.animateCamera(cameraUpdate, durationMillis, null)
        } else {
            map.animateCamera(cameraUpdate)
        }
    }

    override fun getVisibleRegion(): PlatformLatLngBounds {
        return Convert.latLngBoundsToPigeon(map.projection.visibleRegion.latLngBounds)
    }

    override fun updateClusterManagers(updates: PlatformClusterManagerUpdates) {
        clusterManagersController.addClusterManagers(updates.toAdd)
        clusterManagersController.removeClusterManagers(updates.toRemove)
    }

    override fun updateMarkers(updates: PlatformMarkerUpdates) {
        markersController.addMarkers(updates.toAdd)
        markersController.updateMarkers(updates.toChange)
        markersController.removeMarkers(updates.toRemove)
    }

    override fun updatePolylines(updates: PlatformPolylineUpdates) {
        polylinesController.addPolylines(updates.toAdd)
        polylinesController.changePolylines(updates.toChange)
        polylinesController.removePolylines(updates.toRemove)
    }

    override fun updatePolygons(updates: PlatformPolygonUpdates) {
        polygonsController.addPolygons(updates.toAdd)
        polygonsController.changePolygons(updates.toChange)
        polygonsController.removePolygons(updates.toRemove)
    }

    override fun updateCircles(updates: PlatformCircleUpdates) {
        circlesController.addCircles(updates.toAdd)
        circlesController.changeCircles(updates.toChange)
        circlesController.removeCircles(updates.toRemove)
    }

    override fun updateGroundOverlays(updates: PlatformGroundOverlayUpdates) {
        if (disposed) {
            throw FlutterError("map_disposed", "Map $id has been disposed.")
        }
        groundOverlaysController.update(updates)
    }

    override fun updateMultiPointOverlays(updates: PlatformMultiPointOverlayUpdates) {
        throw FlutterError(
            "unsupported",
            "Multi-point overlays are not implemented by this Android renderer."
        )
    }

    override fun updateHeatmaps(updates: PlatformHeatmapUpdates) {
        if (disposed) {
            throw FlutterError("map_disposed", "Map $id has been disposed.")
        }
        heatmapsController.update(updates)
    }

    override fun updateTileOverlays(updates: PlatformTileOverlayUpdates) {
        if (disposed) {
            throw FlutterError("map_disposed", "Map $id has been disposed.")
        }
        tileOverlaysController.update(updates)
    }

    override fun clearTileCache(tileOverlayId: String) {
        if (disposed) {
            throw FlutterError("map_disposed", "Map $id has been disposed.")
        }
        tileOverlaysController.clearTileCache(tileOverlayId)
    }

    override fun showInfoWindow(markerId: String) {
        markersController.showMarkerInfoWindow(markerId)
    }

    override fun hideInfoWindow(markerId: String) {
        markersController.hideMarkerInfoWindow(markerId)
    }

    override fun isInfoWindowShown(markerId: String) =
        markersController.isInfoWindowShown(markerId)

    override fun getZoomLevel() = map.cameraPosition.zoom.toDouble()

    override fun takeSnapshot(failWithStatus: Boolean, callback: (Result<ByteArray>) -> Unit) {
        map.getMapScreenShot(object : AMap.OnMapScreenShotListener {
            override fun onMapScreenShot(bitmap: Bitmap?) {
            }
            override fun onMapScreenShot(bitmap: Bitmap?, status: Int) {
                if (bitmap == null) {
                    callback(Result.failure(FlutterError("Snapshot failure", "Unable to take snapshot")))
                    return
                }
                if (status == 0 && failWithStatus) {
                    callback(Result.failure(FlutterError("not rendered", "not rendered")))
                    return
                }

                val bytes = ByteArrayOutputStream().use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    stream.toByteArray()
                }
                bitmap.recycle()
                callback(Result.success(bytes))
            }
        })
    }

    override fun disposeMap() {
        dispose()
    }

    // AMapOptionsSink

    override fun onMapLoaded() {
        if (disposed) return
        mapLoaded = true
        mapReadyCallback?.invoke(Result.success(Unit))
        mapReadyCallback = null
    }

    override fun setMapType(mapType: Int) {
        map.mapType = mapType
    }

    override fun setCustomMapStyleOptions(customMapStyleOptions: CustomMapStyleOptions?) {
        map.setCustomMapStyle(customMapStyleOptions ?: CustomMapStyleOptions().setEnable(false))
    }

    override fun setMyLocationStyle(myLocationStyle: MyLocationStyle?) {
        myLocationStyle?.let { map.myLocationStyle = it }
    }

    override fun setMyLocationEnabled(enabled: Boolean) {
        if (enabled &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw FlutterError(
                "location_permission",
                "Foreground location permission is required before enabling the location layer."
            )
        }
        map.isMyLocationEnabled = enabled
        if (enabled) {
            map.setOnMyLocationChangeListener(this)
        } else {
            map.setOnMyLocationChangeListener(null)
        }
    }

    override fun setMinMaxZoomPreference(min: Float?, max: Float?) {
        map.resetMinMaxZoomPreference()
        min?.let { map.minZoomLevel = it }
        max?.let { map.maxZoomLevel = it }
    }

    override fun setLatLngBounds(latLngBounds: LatLngBounds?) {
        map.setMapStatusLimits(latLngBounds)
    }

    override fun setTrafficEnabled(trafficEnabled: Boolean) {
        map.isTrafficEnabled = trafficEnabled
    }

    override fun setTouchPoiEnabled(touchPoiEnabled: Boolean) {
        map.isTouchPoiEnable = touchPoiEnabled
    }

    override fun setBuildingsEnabled(buildingsEnabled: Boolean) {
        map.showBuildings(buildingsEnabled)
    }

    override fun setLabelsEnabled(labelsEnabled: Boolean) {
        map.showMapText(labelsEnabled)
    }

    override fun setCompassEnabled(compassEnabled: Boolean) {
        map.uiSettings.isCompassEnabled = compassEnabled
    }

    override fun setScaleEnabled(scaleEnabled: Boolean) {
        map.uiSettings.isScaleControlsEnabled = scaleEnabled
    }

    override fun setZoomGesturesEnabled(zoomGesturesEnabled: Boolean) {
        map.uiSettings.isZoomGesturesEnabled = zoomGesturesEnabled
    }

    override fun setScrollGesturesEnabled(scrollGesturesEnabled: Boolean) {
        map.uiSettings.isScrollGesturesEnabled = scrollGesturesEnabled
    }

    override fun setRotateGesturesEnabled(rotateGesturesEnabled: Boolean) {
        map.uiSettings.isRotateGesturesEnabled = rotateGesturesEnabled
    }

    override fun setTiltGesturesEnabled(tiltGesturesEnabled: Boolean) {
        map.uiSettings.isTiltGesturesEnabled = tiltGesturesEnabled
    }

    override fun setInitialClusterManagers(initialClusterManager: List<PlatformClusterManager>?) {
        initialClusterManager?.let(clusterManagersController::addClusterManagers)
    }

    override fun setInitialMarkers(initialMarkers: List<PlatformMarker>) {
        markersController.addMarkers(initialMarkers)
    }

    override fun setInitialPolylines(initialPolylines: List<PlatformPolyline>) {
        polylinesController.addPolylines(initialPolylines)
    }

    override fun setInitialPolygons(initialPolygons: List<PlatformPolygon>) {
        polygonsController.addPolygons(initialPolygons)
    }

    override fun setInitialCircles(initialCircles: List<PlatformCircle>) {
        circlesController.addCircles(initialCircles)
    }

    override fun setInitialHeatmaps(initialHeatmaps: List<PlatformHeatmap>) {
        heatmapsController.addHeatmaps(initialHeatmaps)
    }

    override fun setInitialTileOverlays(initialTileOverlays: List<PlatformTileOverlay>) {
        tileOverlaysController.addTileOverlays(initialTileOverlays)
    }

    override fun setInitialGroundOverlays(initialGroundOverlays: List<PlatformGroundOverlay>) {
        groundOverlaysController.addGroundOverlays(initialGroundOverlays)
    }


    override fun onMapClick(latLng: LatLng) {
        flutterApi.onTap(Convert.latLngToPigeon(latLng)) { }
    }

    override fun onMapLongClick(latLng: LatLng) {
        flutterApi.onLongPress(Convert.latLngToPigeon(latLng)) { }
    }

    override fun onCameraChange(position: CameraPosition) {
        flutterApi.onCameraMove(Convert.cameraPositionToPigeon(position)) { }
    }

    override fun onCameraChangeFinish(position: CameraPosition) {
        clusterManagersController.onCameraIdle()
        flutterApi.onCameraMoveEnd(Convert.cameraPositionToPigeon(position)) { }
    }


    // ActivityPluginBinding


    override fun onSaveInstanceState(bundle: Bundle) {
        if (disposed) return
        mapView.onSaveInstanceState(bundle)
    }

    override fun onRestoreInstanceState(bundle: Bundle?) {
        if (disposed) return
        mapView.onCreate(bundle)
    }

    override fun onMyLocationChange(location: Location) {
        if (disposed) return
        flutterApi.onMyLocationChange(
            PlatformMyLocation(
                latitude = location.latitude,
                longitude = location.longitude,
                accuracy = if (location.hasAccuracy()) location.accuracy.toDouble() else null,
                altitude = if (location.hasAltitude()) location.altitude else null,
                speed = if (location.hasSpeed()) location.speed.toDouble() else null,
                bearing = if (location.hasBearing()) location.bearing.toDouble() else null,
                timestamp = location.time.takeIf { it > 0L },
            )
        ) { }
    }
}
