import 'package:amap_kit_map_platform_interface/src/types/ground_overlay.dart';
import 'package:amap_kit_map_platform_interface/src/types/maps_object_updates.dart';

/// Add, change, and remove diff for ground overlays.
final class GroundOverlayUpdates extends MapsObjectUpdates<GroundOverlay> {
  /// Computes the difference between two ground-overlay collections.
  GroundOverlayUpdates.from(super.previous, super.current)
    : super.from(objectName: 'groundOverlay');

  /// Ground overlays to add.
  Set<GroundOverlay> get groundOverlaysToAdd => objectsToAdd;

  /// Ground-overlay identifiers to remove.
  Set<GroundOverlayId> get groundOverlayIdsToRemove =>
      objectIdsToRemove.cast<GroundOverlayId>();

  /// Ground overlays to replace with changed values.
  Set<GroundOverlay> get groundOverlaysToChange => objectsToChange;
}
