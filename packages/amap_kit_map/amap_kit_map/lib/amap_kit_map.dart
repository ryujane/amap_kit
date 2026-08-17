library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';

export 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart'
    show
        ArgumentCallback,
        ArgumentCallbacks,
        AssetMapBitmap,
        BitmapDescriptor,
        BytesMapBitmap,
        CameraPosition,
        CameraPositionCallback,
        CameraUpdate,
        Circle,
        CircleId,
        Cluster,
        ClusterManager,
        ClusterManagerId,
        Heatmap,
        HeatmapGradient,
        HeatmapGradientColor,
        HeatmapId,
        HeatmapRadius,
        GroundOverlay,
        GroundOverlayId,
        MapBitmap,
        MapBitmapScaling,
        Tile,
        TileOverlay,
        TileOverlayId,
        TileProvider,
        Marker,
        MarkerId,
        PolygonId,
        Polygon,
        Polyline,
        PolylineId,
        LatLng,
        LatLngBounds,
        AmapMyLocation,
        WeightedLatLng;

part 'src/controller.dart';

part 'src/amap_map.dart';
