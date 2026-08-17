#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint amap_kit_location_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'amap_kit_location_ios'
  s.version          = '0.1.0'
  s.summary          = 'iOS implementation of amap_kit_location.'
  s.description      = 'Foreground AMap location implementation for Flutter.'
  s.homepage         = 'https://github.com/ryujane/amap_kit'
  s.license          = { :type => 'Copyright' }
  s.author           = { 'AMap Flutter Kit' => 'ryujane713@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'amap_kit_location_ios/Sources/amap_kit_location_ios/**/*.{h,m,swift}'
  s.dependency 'Flutter'
  s.dependency 'AMapLocation', '2.12.2'
  s.platform = :ios, '13.0'
  s.static_framework = true
  s.resource_bundles = {
    'amap_kit_location_ios_privacy' => [
      'amap_kit_location_ios/Sources/amap_kit_location_ios/PrivacyInfo.xcprivacy'
    ]
  }

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
