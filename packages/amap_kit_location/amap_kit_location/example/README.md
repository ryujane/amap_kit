# amap_kit_location 示例

通过 `--dart-define=AMAP_API_KEY=<key>` 传入高德 API Key 后运行（Android 使用 Android Key，iOS 使用 iOS Key）；也可以直接在示例页面的输入框中填写。

```shell
flutter run --dart-define=AMAP_API_KEY=your-amap-key
```

示例演示前台单次定位（`getCurrentLocation`）与持续定位（`start`/`stop` + `locations` 流），并开启逆地理地址（`needAddress`），结果会展示在页面上。
