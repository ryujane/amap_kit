package com.github.amapkit.map

import android.content.Context
import com.amap.api.maps.MapsInitializer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class AmapMapPlatformViewFactory(
    private val binaryMessenger: BinaryMessenger,
    private val lifecycleProvider: LifecycleProvider
) : PlatformViewFactory(MapsApi.codec) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = requireNotNull(args as? PlatformMapViewCreationParams) {
            "PlatformMapViewCreationParams are required to create an AMap view."
        }
        val density = context.resources.displayMetrics.density
        val builder = AmapBuilder()
        Convert.interpretMapConfiguration(
            params.mapConfiguration,
            builder,
            context.assets,
            density,
            Convert.BitmapDescriptorFactoryWrapper()
        )

        params.apiKey.takeIf(String::isNotEmpty)?.let(MapsInitializer::setApiKey)
        params.privacyStatement.apply {
            if (hasShow != null && hasContains != null) {
                MapsInitializer.updatePrivacyShow(context, hasShow, hasContains)
            }
            hasAgree?.let { MapsInitializer.updatePrivacyAgree(context, it) }
        }

        builder.apply {
            setInitialCameraPosition(
                Convert.cameraPositionFromPigeon(params.initialCameraPosition)
            )
            setInitialMarkers(params.initialMarkers)
            setInitialPolygons(params.initialPolygons)
            setInitialPolylines(params.initialPolylines)
            setInitialCircles(params.initialCircles)
            setInitialHeatmaps(params.initialHeatmaps)
            setInitialTileOverlays(params.initialTileOverlays)
            setInitialGroundOverlays(params.initialGroundOverlays)
            setInitialClusterManagers(params.initialClusterManagers)
        }
        return builder.build(
            viewId,
            context.applicationContext,
            binaryMessenger,
            lifecycleProvider
        )
    }
}
