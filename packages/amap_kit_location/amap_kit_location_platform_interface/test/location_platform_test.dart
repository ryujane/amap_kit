import 'package:amap_kit_core/amap_kit_core.dart';
import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  test('允许带 MockPlatformInterfaceMixin 的测试替身', () {
    final _MockLocationPlatform platform = _MockLocationPlatform();

    AmapLocationPlatform.instance = platform;

    expect(AmapLocationPlatform.instance, same(platform));
  });

  test('默认方法明确报告不支持', () {
    final _MinimalLocationPlatform platform = _MinimalLocationPlatform();

    expect(
      () => platform.setApiKey('test-api-key'),
      throwsA(isA<AmapLocationUnsupportedException>()),
    );
    expect(
      () => platform.setLocationOption(1, const AmapLocationOptions()),
      throwsA(isA<AmapLocationUnsupportedException>()),
    );
    expect(() => platform.locationsForClient(1), returnsNormally);
  });

  test('结果模型允许平台无法确定坐标系', () {
    final AmapLocationResult result = AmapLocationResult(
      position: const LatLng(30, 120),
      timestamp: DateTime.utc(2026),
      accuracyMeters: 3,
    );

    expect(result.coordinateType, isNull);
  });

  test('结果模型承载结构化逆地理地址', () {
    final AmapLocationResult result = AmapLocationResult(
      position: const LatLng(30, 120),
      timestamp: DateTime.utc(2026),
      accuracyMeters: 3,
      address: const AmapLocationAddress(
        formattedAddress: '浙江省杭州市西湖区',
        city: '杭州市',
        adCode: '330106',
      ),
    );

    expect(result.address?.formattedAddress, '浙江省杭州市西湖区');
    expect(result.address?.city, '杭州市');
    expect(result.address?.adCode, '330106');
  });
}

final class _MockLocationPlatform extends AmapLocationPlatform
    with MockPlatformInterfaceMixin {}

final class _MinimalLocationPlatform extends AmapLocationPlatform {}
