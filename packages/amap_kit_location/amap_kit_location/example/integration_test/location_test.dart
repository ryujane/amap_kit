import 'package:amap_kit_location/amap_kit_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真实设备完成单次定位和持续定位生命周期', (WidgetTester tester) async {
    await AmapLocation.setPrivacyStatus(
      const AmapLocationPrivacyStatus(
        privacyNoticeShown: true,
        containsAmapPrivacyPolicy: true,
        userAgreed: true,
      ),
    );
    final AmapLocationClient client = AmapLocationClient();
    addTearDown(client.dispose);
    // 权限由真机系统弹框授权；未授权时下方调用会抛出
    // AmapLocationPermissionException 使测试失败。
    final AmapLocationResult current = await client.getCurrentLocation();
    expect(current.accuracyMeters, greaterThanOrEqualTo(0));

    final Future<AmapLocationResult> next = client.locations.first;
    await client.start();
    expect((await next).accuracyMeters, greaterThanOrEqualTo(0));
    await client.stop();
    await client.start();
    await client.stop();
  });
}
