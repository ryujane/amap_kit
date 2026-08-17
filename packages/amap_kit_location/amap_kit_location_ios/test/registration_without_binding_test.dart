import 'package:amap_kit_location_ios/amap_kit_location_ios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers before the Flutter binding is initialized', () {
    expect(AmapLocationIos.registerWith, returnsNormally);
  });
}
