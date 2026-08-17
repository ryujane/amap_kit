import CoreLocation
import UIKit

extension PlatformLatLng {
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

extension CLLocationCoordinate2D {
  var platform: PlatformLatLng {
    PlatformLatLng(latitude: latitude, longitude: longitude)
  }
}

func amapColor(_ argb: Int64) -> UIColor {
  let value = UInt64(bitPattern: argb)
  return UIColor(
    red: CGFloat((value >> 16) & 0xff) / 255,
    green: CGFloat((value >> 8) & 0xff) / 255,
    blue: CGFloat(value & 0xff) / 255,
    alpha: CGFloat((value >> 24) & 0xff) / 255)
}

func amapPigeonError(_ code: String, _ message: String) -> PigeonError {
  PigeonError(code: code, message: message, details: nil)
}
