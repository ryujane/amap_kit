import 'package:amap_kit_map_platform_interface/src/types/types.dart';

/// Converts an [Iterable] of Markers in a Map of MarkerId -> Marker.
Map<MarkerId, Marker> keyByMarkerId(Iterable<Marker> markers) {
  return keyByMapsObjectId<Marker>(markers).cast<MarkerId, Marker>();
}

/// Converts a Set of Markers into something serializable in JSON.
Object serializeMarkerSet(Set<Marker> markers) {
  return serializeMapsObjectSet(markers);
}
