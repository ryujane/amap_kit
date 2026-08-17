import 'package:amap_kit_location_android/amap_kit_location_android.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registers before the Flutter binding is initialized', () {
    expect(AmapLocationAndroid.registerWith, returnsNormally);
  });
}
