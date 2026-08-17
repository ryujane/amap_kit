package com.github.amapkit.map.collections

import com.amap.api.maps.AMap
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.MarkerOptions

class MarkerManager(
    map: AMap
) : MapObjectManager<Marker, MarkerCollection>(map),
    AMap.OnMarkerClickListener,
    AMap.OnMarkerDragListener,
    AMap.OnInfoWindowClickListener {

    val defaultCollection by lazy(::createCollection)

    override fun registerMapListeners() {
        map.setOnMarkerClickListener(this)
        map.setOnMarkerDragListener(this)
        map.setOnInfoWindowClickListener(this)
    }

    override fun createCollection() = MarkerCollection(this)

    fun addMarker(options: MarkerOptions) = defaultCollection.addMarker(options)

    override fun onMarkerClick(marker: Marker) =
        objectCollections[marker]?.markerClickListener?.onMarkerClick(marker) ?: false

    override fun onMarkerDragStart(marker: Marker) {
        objectCollections[marker]?.markerDragListener?.onMarkerDragStart(marker)
    }

    override fun onMarkerDrag(marker: Marker) {
        objectCollections[marker]?.markerDragListener?.onMarkerDrag(marker)
    }

    override fun onMarkerDragEnd(marker: Marker) {
        objectCollections[marker]?.markerDragListener?.onMarkerDragEnd(marker)
    }

    override fun onInfoWindowClick(marker: Marker) {
        objectCollections[marker]?.infoWindowClickListener?.onInfoWindowClick(marker)
    }

    fun dispose() {
        objectCollections.keys.toList().forEach(::remove)
        map.setOnMarkerClickListener(null)
        map.setOnMarkerDragListener(null)
        map.setOnInfoWindowClickListener(null)
    }
}

class MarkerCollection(private val manager: MarkerManager) : ObjectCollection<Marker>(
    onRemove = { marker ->
        marker.remove()
        manager.unregisterObject(marker)
    }
) {
    var infoWindowClickListener: AMap.OnInfoWindowClickListener? = null
    var markerClickListener: AMap.OnMarkerClickListener? = null
    var markerDragListener: AMap.OnMarkerDragListener? = null

    fun addMarker(options: MarkerOptions): Marker = manager.map.addMarker(options).also { marker ->
        addObject(marker)
        manager.registerObject(marker, this)
    }
}
