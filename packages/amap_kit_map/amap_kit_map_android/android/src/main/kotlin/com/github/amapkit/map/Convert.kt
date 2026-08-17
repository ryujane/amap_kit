package com.github.amapkit.map

import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import androidx.annotation.VisibleForTesting
import androidx.core.graphics.scale
import com.amap.api.maps.AMap
import com.amap.api.maps.CameraUpdate
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.model.AMapPara
import com.amap.api.maps.model.BaseHoleOptions
import com.amap.api.maps.model.BitmapDescriptor
import com.amap.api.maps.model.BitmapDescriptorFactory
import com.amap.api.maps.model.CameraPosition
import com.amap.api.maps.model.CustomMapStyleOptions
import com.amap.api.maps.model.Gradient
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.LatLngBounds
import com.amap.api.maps.model.MyLocationStyle
import com.amap.api.maps.model.PolygonHoleOptions
import com.amap.api.maps.model.PolylineOptions
import com.amap.api.maps.model.TileProvider
import com.amap.api.maps.model.WeightedLatLng
import com.github.amapkit.map.overlays.circle.CircleOptionsSink
import com.github.amapkit.map.overlays.clustering.Cluster
import com.github.amapkit.map.overlays.ground.GroundOverlayOptionsSink
import com.github.amapkit.map.overlays.heatmap.HeatmapOptionsSink
import com.github.amapkit.map.overlays.marker.MarkerBuilder
import com.github.amapkit.map.overlays.marker.MarkerOptionsSink
import com.github.amapkit.map.overlays.polygon.PolygonOptionsSink
import com.github.amapkit.map.overlays.polyline.PolylineOptionsSink
import com.github.amapkit.map.overlays.tile.TileOverlayOptionsSink
import io.flutter.FlutterInjector

object Convert {

    fun interpretGroundOverlayOptions(
        overlay: PlatformGroundOverlay,
        sink: GroundOverlayOptionsSink,
        assetManager: AssetManager,
        density: Float,
        wrapper: BitmapDescriptorFactoryWrapper
    ): String {
        sink.setImage(toBitmapDescriptor(overlay.image, assetManager, density, wrapper))
        val bounds = overlay.bounds
        if (bounds != null) {
            sink.setPositionFromBounds(latLngBoundsFromPigeon(bounds))
        } else {
            val position = requireNotNull(overlay.position) {
                "Ground overlay ${overlay.id} must define position or bounds."
            }
            val width = requireNotNull(overlay.width) {
                "Ground overlay ${overlay.id} must define width for position placement."
            }
            sink.setPosition(
                latLngFromPigeon(position),
                width.toFloat(),
                overlay.height?.toFloat()
            )
        }
        sink.setAnchor(overlay.anchor.x.toFloat(), overlay.anchor.y.toFloat())
        sink.setBearing(overlay.bearing.toFloat())
        sink.setTransparency(overlay.transparency.toFloat())
        sink.setZIndex(overlay.zIndex.toFloat())
        sink.setVisible(overlay.visible)
        return overlay.id
    }

    fun interpretTileOverlayOptions(
        options: PlatformTileOverlay,
        sink: TileOverlayOptionsSink,
        tileProvider: TileProvider
    ): String {
        sink.setTileProvider(tileProvider)
        sink.setTileSize(options.tileSize.toInt())
        sink.setZIndex(options.zIndex.toFloat())
        sink.setVisible(options.visible)
        return options.id
    }

    fun interpretMapConfiguration(
        config: PlatformMapOptions, sink: AMapOptionsSink,
        assetManager: AssetManager,
        density: Float,
        wrapper: BitmapDescriptorFactoryWrapper
    ) {
        val compassEnabled: Boolean? = config.compassEnabled
        if (compassEnabled != null) {
            sink.setCompassEnabled(compassEnabled)
        }
        val mapType: PlatformMapType? = config.mapType
        if (mapType != null) {
            sink.setMapType(toMapType(mapType))
        }
        val myLocationStyle = config.myLocationStyle
        sink.setMyLocationStyle(
            myLocationStyle?.let { toMyLocationStyle(it, assetManager, density, wrapper) }
        )
        config.myLocationEnabled?.let(sink::setMyLocationEnabled)
        sink.setCustomMapStyleOptions(config.customMapStyle?.let(::toCustomMapStyle))
        val scaleControlsEnabled: Boolean? = config.scaleControlsEnabled
        if (scaleControlsEnabled != null) {
            sink.setScaleEnabled(scaleControlsEnabled)
        }
        val zoomGesturesEnabled: Boolean? = config.zoomGesturesEnabled
        if (zoomGesturesEnabled != null) {
            sink.setZoomGesturesEnabled(zoomGesturesEnabled)
        }
        config.rotateGesturesEnabled?.let(sink::setRotateGesturesEnabled)
        config.scrollGesturesEnabled?.let(sink::setScrollGesturesEnabled)
        config.tiltGesturesEnabled?.let(sink::setTiltGesturesEnabled)

        val trafficEnabled: Boolean? = config.trafficEnabled
        if (trafficEnabled != null) {
            sink.setTrafficEnabled(trafficEnabled)
        }
        val buildingsEnabled: Boolean? = config.buildingsEnabled
        if (buildingsEnabled != null) {
            sink.setBuildingsEnabled(buildingsEnabled)
        }
    }


    fun interpretMarkerOptions(
        marker: PlatformMarker,
        sink: MarkerOptionsSink,
        assetManager: AssetManager,
        density: Float,
        wrapper: BitmapDescriptorFactoryWrapper
    ) {
        sink.setAlpha(marker.alpha.toFloat())
        sink.setAnchor(marker.anchor.x.toFloat(), marker.anchor.y.toFloat())
        sink.setDraggable(marker.draggable)
        sink.setFlat(marker.flat)
        sink.setRotation(marker.rotation.toFloat())
        sink.setPosition(latLngFromPigeon(marker.position))
        sink.setIcon(
            toBitmapDescriptor(
                marker.icon,
                assetManager,
                density,
                wrapper
            )
        )
        sink.setTitle(marker.infoWindow.title ?: marker.title)
        sink.setSnippet(marker.infoWindow.snippet ?: marker.snippet)
        sink.setInfoWindowEnable(
            marker.infoWindow.title != null || marker.infoWindow.snippet != null ||
                marker.title != null || marker.snippet != null
        )
        sink.setConsumeTapEvents(marker.consumeTapEvents)
        sink.setVisible(marker.visible)
        sink.setZIndex(marker.zIndex.toFloat())
    }


    fun interpretPolylineOptions(
        polyline: PlatformPolyline,
        sink: PolylineOptionsSink,
        assetManager: AssetManager,
        density: Float
    ): String {
        sink.setConsumeTapEvents(polyline.consumesTapEvents)
        sink.setColor(polyline.color.toInt())
        sink.setGeodesic(polyline.geodesic)
        sink.setVisible(polyline.visible)
        sink.setWidth(polyline.width.toFloat())
        sink.setZIndex(polyline.zIndex.toFloat())
        sink.setPoints(pointsFromPigeon(polyline.points))
        sink.setLineCapType(toLineCapType(polyline.lineCapType))
        sink.setLineJoinType(toLineJoinType(polyline.lineJoinType))
        sink.setDashLine(polyline.isDotted)
        return polyline.polylineId
    }

    fun interpretPolygonOptions(
        polygon: PlatformPolygon,
        sink: PolygonOptionsSink
    ): String {
        sink.setFillColor(polygon.fillColor.toInt())
        sink.setStrokeColor(polygon.strokeColor.toInt())
        sink.setStrokeWidth(polygon.strokeWidth.toFloat())
        sink.setVisible(polygon.visible)
        sink.setZIndex(polygon.zIndex.toFloat())
        sink.setPoints(pointsFromPigeon(polygon.points))
        sink.setHoles(holesFromPigeon(polygon.holes))
        sink.setLineJoinType(toPolygonLineJoinType(polygon.lineJoinType))
        return polygon.polygonId
    }

    fun interpretCircleOptions(
        circle: PlatformCircle,
        sink: CircleOptionsSink
    ): String {
        sink.setCenter(latLngFromPigeon(circle.center))
        sink.setRadius(circle.radius)
        sink.setStrokeColor(circle.strokeColor.toInt())
        sink.setFillColor(circle.fillColor.toInt())
        sink.setStrokeWidth(circle.strokeWidth.toFloat())
        sink.setVisible(circle.visible)
        sink.setZIndex(circle.zIndex.toFloat())
        // AMap 的 Circle 用虚线类型而非布尔值表示是否虚线：true 取方块虚线，
        // false 回到默认（实线）。
        sink.setStrokeDottedLineType(
            if (circle.isDotted) AMapPara.DOTTEDLINE_TYPE_SQUARE
            else AMapPara.DOTTEDLINE_TYPE_DEFAULT
        )
        return circle.circleId
    }

    fun interpretHeatmapOptions(
        heatmap: PlatformHeatmap,
        sink: HeatmapOptionsSink
    ): String {
        sink.setData(
            heatmap.data.map { point ->
                WeightedLatLng(latLngFromPigeon(point.point), point.weight)
            }
        )
        heatmap.gradient?.let { sink.setGradient(gradientFromPigeon(it)) }
        sink.setOpacity(heatmap.opacity)
        sink.setRadius(heatmap.radius.toInt())
        sink.setVisible(heatmap.visible)
        return heatmap.id
    }

    fun gradientFromPigeon(gradient: PlatformHeatmapGradient): Gradient {
        val colors = gradient.colors.map { it.toInt() }.toIntArray()
        val startPoints = gradient.startPoints.map { it.toFloat() }.toFloatArray()
        return Gradient(colors, startPoints)
    }

    fun cameraPositionFromPigeon(
        position: PlatformCameraPosition
    ): CameraPosition {
        val builder: CameraPosition.Builder = CameraPosition.builder()
        builder.bearing(position.bearing.toFloat())
        builder.target(latLngFromPigeon(position.target))
        builder.tilt(position.tilt.toFloat())
        builder.zoom(position.zoom.toFloat())
        return builder.build()
    }

    fun cameraPositionToPigeon(position: CameraPosition): PlatformCameraPosition {
        return PlatformCameraPosition(
            latLngToPigeon(position.target),
            position.zoom.toDouble(),
            position.bearing.toDouble(),
            position.tilt.toDouble(),
        )
    }

    fun toMapType(type: PlatformMapType): Int {
        return when (type) {
            PlatformMapType.SATELLITE -> AMap.MAP_TYPE_SATELLITE
            PlatformMapType.NORMAL -> AMap.MAP_TYPE_NORMAL
        }
    }

    private fun holesFromPigeon(holes: List<List<PlatformLatLng>>): List<BaseHoleOptions> {
        return holes.map { ring ->
            PolygonHoleOptions().addAll(ring.map { latLngFromPigeon(it) })
        }
    }

    fun cameraUpdateFromPigeon(update: PlatformCameraUpdate, density: Float): CameraUpdate {
        val cameraUpdate: Any = update.cameraUpdate
        if (cameraUpdate is PlatformCameraUpdateNewCameraPosition) {
            return CameraUpdateFactory.newCameraPosition(
                cameraPositionFromPigeon(cameraUpdate.cameraPosition)
            )
        }
        if (cameraUpdate is PlatformCameraUpdateNewLatLng) {
            return CameraUpdateFactory.newLatLng(
                latLngFromPigeon(
                    cameraUpdate.latLng
                )
            )
        }
        if (cameraUpdate is PlatformCameraUpdateNewLatLngZoom) {
            return CameraUpdateFactory.newLatLngZoom(
                latLngFromPigeon(cameraUpdate.latLng),
                cameraUpdate.zoom.toFloat()
            )
        }
        if (cameraUpdate is PlatformCameraUpdateNewLatLngBounds) {
            return CameraUpdateFactory.newLatLngBounds(
                latLngBoundsFromPigeon(cameraUpdate.bounds),
                (cameraUpdate.padding * density).toInt()
            )
        }
        if (cameraUpdate is PlatformCameraUpdateScrollBy) {
            return CameraUpdateFactory.scrollBy(
                cameraUpdate.dx.toFloat() * density, cameraUpdate.dy.toFloat() * density
            )
        }
        if (cameraUpdate is PlatformCameraUpdateZoomBy) {
            val focus: Point? = pointFromPigeon(
                cameraUpdate.focus,
                density
            )
            return if (focus != null)
                CameraUpdateFactory.zoomBy(cameraUpdate.amount.toFloat(), focus)
            else
                CameraUpdateFactory.zoomBy(cameraUpdate.amount.toFloat())
        }
        if (cameraUpdate is PlatformCameraUpdateZoomTo) {
            return CameraUpdateFactory.zoomTo(cameraUpdate.zoom.toFloat())
        }
        if (cameraUpdate is PlatformCameraUpdateZoom) {
            return if (cameraUpdate.out) CameraUpdateFactory.zoomOut() else CameraUpdateFactory.zoomIn()
        }
        throw java.lang.IllegalArgumentException(
            "PlatformCameraUpdate's cameraUpdate field must be one of the PlatformCameraUpdate... case"
                    + " classes."
        )
    }

    fun pointFromPigeon(point: PlatformPoint): Point {
        return Point(point.x.toInt(), point.y.toInt())
    }

    fun pointFromPigeon(point: PlatformDoublePair?, density: Float): Point? {
        if (point == null) {
            return null
        }
        return Point((point.x * density).toInt(), (point.y * density).toInt())
    }

    private fun toPolygonLineJoinType(type: PlatformLineJoinType): AMapPara.LineJoinType {
        return when (type) {
            PlatformLineJoinType.BEVEL -> AMapPara.LineJoinType.LineJoinBevel
            PlatformLineJoinType.MITER -> AMapPara.LineJoinType.LineJoinMiter
            PlatformLineJoinType.ROUND -> AMapPara.LineJoinType.LineJoinRound
        }
    }

    private fun toLineJoinType(type: PlatformLineJoinType) =
        when (type) {
            PlatformLineJoinType.BEVEL -> PolylineOptions.LineJoinType.LineJoinBevel
            PlatformLineJoinType.MITER -> PolylineOptions.LineJoinType.LineJoinMiter
            PlatformLineJoinType.ROUND -> PolylineOptions.LineJoinType.LineJoinRound
        }

    private fun toLineCapType(type: PlatformLineCapType) =
        when (type) {
            PlatformLineCapType.BUTT -> PolylineOptions.LineCapType.LineCapButt
            PlatformLineCapType.SQUARE -> PolylineOptions.LineCapType.LineCapSquare
            PlatformLineCapType.ARROW -> PolylineOptions.LineCapType.LineCapArrow
            PlatformLineCapType.ROUND -> PolylineOptions.LineCapType.LineCapRound
        }

    private fun pointsFromPigeon(data: List<PlatformLatLng>): MutableList<LatLng?> =
        data.mapTo(mutableListOf()) { LatLng(it.latitude, it.longitude) }

    @VisibleForTesting
    fun getBitmapFromAsset(
        assetMap: PlatformBitmapAssetMap,
        assetManager: AssetManager,
        density: Float,
        bitmapDescriptorFactory: BitmapDescriptorFactoryWrapper,
        flutterInjector: FlutterInjectorWrapper
    ): BitmapDescriptor {
        val assetName: String = assetMap.assetName
        val assetKey: String = flutterInjector.getLookupKeyForAsset(assetName)

        val scalingMode: PlatformMapBitmapScaling = assetMap.bitmapScaling
        when (scalingMode) {
            PlatformMapBitmapScaling.AUTO -> {
                val width: Double? = assetMap.width
                val height: Double? = assetMap.height
                try {
                    assetManager.open(assetKey).use { inputStream ->
                        val bitmap = BitmapFactory.decodeStream(inputStream)
                        if (width != null || height != null) {
                            var targetWidth =
                                if (width != null) toInt(width * density) else bitmap.getWidth()
                            var targetHeight =
                                if (height != null) toInt(
                                    height * density
                                ) else bitmap.getHeight()

                            if (width != null && height == null) {
                                // If only width is provided, calculate height based on aspect ratio.
                                val aspectRatio = bitmap.getHeight().toDouble() / bitmap.getWidth()
                                targetHeight = (targetWidth * aspectRatio).toInt()
                            } else if (height != null && width == null) {
                                // If only height is provided, calculate width based on aspect ratio.
                                val aspectRatio = bitmap.getWidth().toDouble() / bitmap.getHeight()
                                targetWidth = (targetHeight * aspectRatio).toInt()
                            }
                            return bitmapDescriptorFactory.fromBitmap(
                                toScaledBitmap(
                                    bitmap,
                                    targetWidth,
                                    targetHeight
                                )
                            )
                        } else {
                            // Scale image using given scale.
                            val scale = (density / assetMap.imagePixelRatio).toFloat()
                            return bitmapDescriptorFactory.fromBitmap(
                                toScaledBitmap(
                                    bitmap,
                                    scale
                                )
                            )
                        }
                    }
                } catch (e: java.lang.Exception) {
                    throw java.lang.IllegalArgumentException(
                        "'asset' cannot open asset: $assetName",
                        e
                    )
                }
            }

            else -> {}
        }

        return bitmapDescriptorFactory.fromAsset(assetKey)
    }

    private fun toInt(o: Any): Int {
        return (o as Number).toInt()
    }

    fun latLngFromPigeon(latLng: PlatformLatLng): LatLng {
        return LatLng(latLng.latitude, latLng.longitude)
    }

    fun latLngToPigeon(latLng: LatLng): PlatformLatLng {
        return PlatformLatLng(latLng.latitude, latLng.longitude)
    }

    fun latLngBoundsToPigeon(latLngBounds: LatLngBounds): PlatformLatLngBounds {
        // PlatformLatLngBounds 的字段顺序是 southwest、northeast（Kotlin 位置参数），
        // 这里必须按该顺序传参，否则 southwest/northeast 会互换，导致 Dart 侧
        // LatLngBounds 断言失败、聚合点点击事件被静默丢弃。
        return PlatformLatLngBounds(
            latLngToPigeon(latLngBounds.southwest),
            latLngToPigeon(latLngBounds.northeast)
        )
    }

    fun latLngBoundsFromPigeon(bounds: PlatformLatLngBounds): LatLngBounds {
        return LatLngBounds(
            latLngFromPigeon(bounds.southwest),
            latLngFromPigeon(bounds.northeast)
        )
    }

    fun clusterToPigeon(
        clusterManagerId: String?,
        cluster: Cluster<MarkerBuilder>
    ): PlatformCluster {
        val clusterManagerId = requireNotNull(clusterManagerId) {
            "A cluster must belong to a cluster manager."
        }
        val latLngBoundsBuilder = LatLngBounds.builder()
        val markerIds = cluster.items.map { markerBuilder ->
            latLngBoundsBuilder.include(markerBuilder.position)
            markerBuilder.markerId
        }

        return PlatformCluster(
            clusterManagerId,
            markerIds,
            latLngToPigeon(cluster.position),
            latLngBoundsToPigeon(latLngBoundsBuilder.build()),
        )
    }
    fun toCustomMapStyle(style: PlatformCustomMapStyle): CustomMapStyleOptions {
        return CustomMapStyleOptions().apply {
            setEnable(true)
            style.styleData?.let { setStyleData(it) }
            style.styleExtraData?.let { setStyleExtraData(it) }
            style.styleTextureData?.let { setStyleTextureData(it) }
            style.styleId?.let { setStyleId(it) }
        }
    }

    fun toMyLocationStyle(
        style: PlatformMyLocationStyle,
        assetManager: AssetManager,
        density: Float,
        wrapper: BitmapDescriptorFactoryWrapper
    ): MyLocationStyle {
        val locationStyle = MyLocationStyle()
        style.icon?.let {
            locationStyle.myLocationIcon(                toBitmapDescriptor(
                it,
                assetManager,
                density,
                wrapper
            ))
        }
        val anchorU = style.anchorU
        val anchorV = style.anchorV
        if (anchorU != null && anchorV != null) {
            locationStyle.anchor(anchorU.toFloat(), anchorV.toFloat())
        }
        style.radiusFillColor?.let { locationStyle.radiusFillColor(it.toInt()) }
        style.strokeColor?.let { locationStyle.strokeColor(it.toInt()) }
        style.strokeWidth?.let { locationStyle.strokeWidth(it.toFloat()) }
        locationStyle.myLocationType(
            style.myLocationType?.let { toMyLocationType(it) }
                ?: MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER
        )
        style.interval?.let { locationStyle.interval(it) }
        style.showMyLocation?.let { locationStyle.showMyLocation(it) }
        style.zIndex?.let { locationStyle.zIndex = it.toInt() }
        return locationStyle
    }

    fun toMyLocationType(type: PlatformMyLocationType): Int {
        return when (type) {
            PlatformMyLocationType.SHOW -> MyLocationStyle.LOCATION_TYPE_SHOW
            PlatformMyLocationType.LOCATE -> MyLocationStyle.LOCATION_TYPE_LOCATE
            PlatformMyLocationType.FOLLOW -> MyLocationStyle.LOCATION_TYPE_FOLLOW
            PlatformMyLocationType.MAP_ROTATE -> MyLocationStyle.LOCATION_TYPE_MAP_ROTATE
            PlatformMyLocationType.LOCATION_ROTATE -> MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE
            PlatformMyLocationType.LOCATION_ROTATE_NO_CENTER -> MyLocationStyle.LOCATION_TYPE_LOCATION_ROTATE_NO_CENTER
            PlatformMyLocationType.FOLLOW_NO_CENTER -> MyLocationStyle.LOCATION_TYPE_FOLLOW_NO_CENTER
            PlatformMyLocationType.MAP_ROTATE_NO_CENTER -> MyLocationStyle.LOCATION_TYPE_MAP_ROTATE_NO_CENTER
        }
    }

    fun toBitmapDescriptor(
        platformBitmap: PlatformBitmap,
        assetManager: AssetManager,
        density: Float,
        wrapper: BitmapDescriptorFactoryWrapper
    ): BitmapDescriptor {
        val bitmap: Any = platformBitmap.bitmap
        if (bitmap is PlatformBitmapDefaultMarker) {
            if (bitmap.hue == null) {
                return BitmapDescriptorFactory.defaultMarker()
            } else {
                val hue: Float = bitmap.hue.toFloat()
                return BitmapDescriptorFactory.defaultMarker(hue)
            }
        }
        if (bitmap is PlatformBitmapAsset) {
            val assetPath: String = bitmap.name
            val assetPackage: String? = bitmap.pkg
            return if (assetPackage == null) {
                BitmapDescriptorFactory.fromAsset(
                    FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
                )
            } else {
                BitmapDescriptorFactory.fromAsset(
                    FlutterInjector.instance()
                        .flutterLoader()
                        .getLookupKeyForAsset(assetPath, assetPackage)
                )
            }
        }
        if (bitmap is PlatformBitmapAssetImage) {
            val assetImagePath: String = bitmap.name
            return BitmapDescriptorFactory.fromAsset(
                FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetImagePath)
            )
        }
        if (bitmap is PlatformBitmapBytes) {
            return getBitmapFromBytesLegacy(bitmap)
        }
        if (bitmap is PlatformBitmapAssetMap) {
            return getBitmapFromAsset(
                bitmap,
                assetManager,
                density,
                wrapper,
                FlutterInjectorWrapper()
            )
        }
        if (bitmap is PlatformBitmapBytesMap) {
            return getBitmapFromBytes(
                bitmap,
                density,
                wrapper
            )
        }
        throw IllegalArgumentException("PlatformBitmap did not contain a supported subtype.")
    }

    private fun toBitmap(bmpData: ByteArray): Bitmap {
        return BitmapFactory.decodeByteArray(bmpData, 0, bmpData.size)
            ?: throw IllegalArgumentException("Unable to decode bytes as a valid bitmap.")
    }

    private fun getBitmapFromBytesLegacy(bitmapBytes: PlatformBitmapBytes): BitmapDescriptor {
        try {
            val bitmap: Bitmap = toBitmap(bitmapBytes.byteData)
            return BitmapDescriptorFactory.fromBitmap(bitmap)
        } catch (e: Exception) {
            throw java.lang.IllegalArgumentException(
                "Unable to interpret bytes as a valid image.",
                e
            )
        }
    }

    @VisibleForTesting
    fun getBitmapFromBytes(
        bytesMap: PlatformBitmapBytesMap,
        density: Float,
        bitmapDescriptorFactory: BitmapDescriptorFactoryWrapper
    ): BitmapDescriptor {
        try {
            val bitmap: Bitmap =
                toBitmap(bytesMap.byteData)
            val scalingMode: PlatformMapBitmapScaling = bytesMap.bitmapScaling
            when (scalingMode) {
                PlatformMapBitmapScaling.AUTO -> {
                    val width: Double? = bytesMap.width
                    val height: Double? = bytesMap.height

                    if (width != null || height != null) {
                        var targetWidth =
                            if (width != null) toInt(width * density) else bitmap.getWidth()
                        var targetHeight =
                            if (height != null) toInt(height * density) else bitmap.getHeight()

                        if (width != null && height == null) {
                            // If only width is provided, calculate height based on aspect ratio.
                            val aspectRatio = bitmap.getHeight().toDouble() / bitmap.getWidth()
                            targetHeight = (targetWidth * aspectRatio).toInt()
                        } else if (width == null) {
                            // If only height is provided, calculate width based on aspect ratio.
                            val aspectRatio = bitmap.getWidth().toDouble() / bitmap.getHeight()
                            targetWidth = (targetHeight * aspectRatio).toInt()
                        }
                        return bitmapDescriptorFactory.fromBitmap(
                            toScaledBitmap(
                                bitmap,
                                targetWidth,
                                targetHeight
                            )
                        )
                    } else {
                        // Scale image using given scale ratio
                        val scale = (density / bytesMap.imagePixelRatio).toFloat()
                        return bitmapDescriptorFactory.fromBitmap(
                            toScaledBitmap(
                                bitmap,
                                scale
                            )
                        )
                    }
                }

                else -> {}
            }
            return bitmapDescriptorFactory.fromBitmap(bitmap)
        } catch (e: java.lang.Exception) {
            throw java.lang.IllegalArgumentException(
                "Unable to interpret bytes as a valid image.",
                e
            )
        }
    }

    private fun toScaledBitmap(bitmap: Bitmap, width: Int, height: Int): Bitmap {
        if (width > 0 && height > 0 && (bitmap.getWidth() != width || bitmap.getHeight() != height)) {
            return bitmap.scale(width, height)
        }
        return bitmap
    }

    private fun toScaledBitmap(bitmap: Bitmap, scale: Float): Bitmap {
        if (scale == 1.0f) {
            return bitmap
        }
        return bitmap.scale(
            (bitmap.getWidth() * scale).toInt(),
            (bitmap.getHeight() * scale).toInt(),
            true,
        )
    }


    class BitmapDescriptorFactoryWrapper {
        /**
         * Creates a BitmapDescriptor from the provided asset key using the [ ].
         *
         *
         * This method is visible for testing purposes only and should never be used outside Convert
         * class.
         *
         * @param assetKey the key of the asset.
         * @return a new instance of the [BitmapDescriptor].
         */
        @VisibleForTesting
        fun fromAsset(assetKey: String?): BitmapDescriptor {
            return BitmapDescriptorFactory.fromAsset(assetKey)
        }

        /**
         * Creates a BitmapDescriptor from the provided bitmap using the [ ].
         *
         *
         * This method is visible for testing purposes only and should never be used outside Convert
         * class.
         *
         * @param bitmap the bitmap to convert.
         * @return a new instance of the [BitmapDescriptor].
         */
        @VisibleForTesting
        fun fromBitmap(bitmap: Bitmap?): BitmapDescriptor {
            return BitmapDescriptorFactory.fromBitmap(bitmap)
        }
    }


    @VisibleForTesting
    class FlutterInjectorWrapper {
        /**
         * Retrieves the lookup key for a given asset name using the [FlutterInjector].
         *
         *
         * This method is visible for testing purposes only and should never be used outside Convert
         * class.
         *
         * @param assetName the name of the asset.
         * @return the lookup key for the asset.
         */
        @VisibleForTesting
        fun getLookupKeyForAsset(assetName: String): String {
            return FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetName)
        }
    }
}
