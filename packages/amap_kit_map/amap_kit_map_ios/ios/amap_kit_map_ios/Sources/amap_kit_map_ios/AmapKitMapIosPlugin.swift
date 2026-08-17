import Flutter

/// Registers the iOS AMap platform view with the Flutter engine.
public final class AmapKitMapIosPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      AmapMapFactory(
        binaryMessenger: registrar.messenger(),
        assetLookup: { asset, package in
          if let package {
            return registrar.lookupKey(forAsset: asset, fromPackage: package)
          }
          return registrar.lookupKey(forAsset: asset)
        }),
      withId: "amap_kit_map/map_ios")
  }
}
