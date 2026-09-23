import 'package:amap_kit_map_android/amap_kit_map_android.dart';
import 'package:amap_kit_map_android/src/messages.g.dart';
import 'package:amap_kit_map_platform_interface/amap_kit_map_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records [MapsApi.updateMapOptions] calls without touching platform
/// channels.
class _RecordingMapsApi extends MapsApi {
  final List<PlatformMapOptions> mapOptions = <PlatformMapOptions>[];

  @override
  Future<void> updateMapOptions(PlatformMapOptions options) async {
    mapOptions.add(options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingMapsApi api;
  late AmapMapsFlutterAndroid platform;

  setUp(() {
    api = _RecordingMapsApi();
    platform = AmapMapsFlutterAndroid(apiProvider: (_) => api);
    platform.ensureApiInitialized(0);
  });

  group('updateMapConfiguration maps MyLocationStyle.icon', () {
    test('null keeps the platform default instead of throwing', () async {
      await platform.updateMapConfiguration(
        const AmapMapConfiguration(
          myLocationEnabled: true,
          myLocationStyle: AmapMyLocationStyle(showMyLocation: true),
        ),
        mapId: 0,
      );

      expect(api.mapOptions.single.myLocationStyle?.icon, isNull);
    });

    test('non-null icon is still converted', () async {
      await platform.updateMapConfiguration(
        const AmapMapConfiguration(
          myLocationStyle: AmapMyLocationStyle(
            icon: BitmapDescriptor.defaultMarker,
          ),
        ),
        mapId: 0,
      );

      expect(
        api.mapOptions.single.myLocationStyle?.icon?.bitmap,
        isA<PlatformBitmapDefaultMarker>(),
      );
    });
  });
}
