import 'dart:typed_data' show ByteData;

import 'package:amap_kit_location_ios/amap_kit_location_ios.dart';
import 'package:amap_kit_location_ios/src/generated/location_messages.g.dart';
import 'package:amap_kit_location_ios/src/location_handler.dart';
import 'package:amap_kit_location_platform_interface/amap_kit_location_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationHandler', () {
    late TestDefaultBinaryMessenger messenger;
    late LocationHandler handler;

    setUp(() {
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      handler = LocationHandler(binaryMessenger: messenger);
    });

    tearDown(() => handler.dispose());

    test('constructor registers the Pigeon callback handler', () async {
      final Future<AmapLocationResult> result = handler
          .locationsForClient(7)
          .first;

      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.amap_kit_location_ios.LocationFlutterApi.onLocation',
        LocationFlutterApi.pigeonChannelCodec.encodeMessage(<Object?>[
          7,
          _location(latitude: 31.2),
        ]),
        null,
      );

      expect((await result).position.latitude, 31.2);
    });

    test('routes events and errors by client id', () async {
      final Future<AmapLocationResult> first = handler
          .locationsForClient(1)
          .first;
      final Future<Object> secondError = handler
          .locationsForClient(2)
          .first
          .then<Object>((AmapLocationResult value) => value)
          .catchError((Object error) => error);

      handler.onLocation(1, _location(latitude: 30));
      handler.onError(2, NativeLocationErrorCode.timeout, 'timeout');

      expect((await first).position.latitude, 30);
      expect(await secondError, isA<AmapLocationTimeoutException>());
    });

    test('closes one client and ignores its late callbacks', () async {
      final Stream<AmapLocationResult> first = handler.locationsForClient(1);
      final Stream<AmapLocationResult> second = handler.locationsForClient(2);
      final Future<void> firstDone = first.drain<void>();
      final Future<AmapLocationResult> secondResult = second.first;

      await handler.closeClient(1);
      handler.onLocation(1, _location(latitude: 1));
      handler.onLocation(2, _location(latitude: 2));

      await firstDone;
      expect((await secondResult).position.latitude, 2);
    });

    test('rejects new streams after disposal', () async {
      await handler.dispose();

      expect(
        () => handler.locationsForClient(1),
        throwsA(isA<AmapLocationDisposedException>()),
      );
      handler.onLocation(1, _location(latitude: 1));
    });
  });

  test(
    'silently ignores Android-only options when calling the host channel',
    () async {
      AmapLocationIos.registerWith();
      const AmapLocationOptions options = AmapLocationOptions(
        android: AmapLocationAndroidOptions(),
      );

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final List<NativeLocationOptions> sentOptions = <NativeLocationOptions>[];
      messenger.setMockMessageHandler(
        'dev.flutter.pigeon.amap_kit_location_ios.LocationHostApi.createClient',
        (ByteData? message) async {
          final List<Object?>? decoded =
              LocationHostApi.pigeonChannelCodec.decodeMessage(message)
                  as List<Object?>?;
          sentOptions.add(decoded!.first! as NativeLocationOptions);
          return LocationHostApi.pigeonChannelCodec.encodeMessage(<Object?>[7]);
        },
      );
      messenger.setMockMessageHandler(
        'dev.flutter.pigeon.amap_kit_location_ios.LocationHostApi.setLocationOption',
        (ByteData? message) async {
          final List<Object?>? decoded =
              LocationHostApi.pigeonChannelCodec.decodeMessage(message)
                  as List<Object?>?;
          sentOptions.add(decoded![1]! as NativeLocationOptions);
          return LocationHostApi.pigeonChannelCodec.encodeMessage(<Object?>[
            null,
          ]);
        },
      );
      addTearDown(() {
        messenger.setMockMessageHandler(
          'dev.flutter.pigeon.amap_kit_location_ios.LocationHostApi.createClient',
          null,
        );
        messenger.setMockMessageHandler(
          'dev.flutter.pigeon.amap_kit_location_ios.LocationHostApi.setLocationOption',
          null,
        );
      });

      expect(await AmapLocationPlatform.instance.createClient(options), 7);
      await AmapLocationPlatform.instance.setLocationOption(1, options);

      // 不抛不支持错误，且发给宿主的选项不含 Android 专属配置。
      expect(sentOptions, hasLength(2));
      expect(
        sentOptions.every((NativeLocationOptions o) => o.ios == null),
        isTrue,
      );
    },
  );
}

NativeLocation _location({required double latitude}) => NativeLocation(
  latitude: latitude,
  longitude: 121.5,
  accuracyMeters: 5,
  timestampMillis: 1,
  coordinateType: NativeCoordinateType.gcj02,
);
