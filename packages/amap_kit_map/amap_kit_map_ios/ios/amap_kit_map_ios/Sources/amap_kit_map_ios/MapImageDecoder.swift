import Foundation
import UIKit

/// Decodes Pigeon bitmap descriptors using the Flutter engine's asset lookup.
final class MapImageDecoder {
  private static let maximumEncodedBytes = 20 * 1024 * 1024
  private static let maximumDimension = 8_192.0
  private static let maximumPixels = 64.0 * 1024 * 1024
  private let lookupAsset: (String, String?) -> String
  private var decodedImages: [PlatformBitmap: UIImage] = [:]

  init(lookupAsset: @escaping (String, String?) -> String) {
    self.lookupAsset = lookupAsset
  }

  func image(for descriptor: PlatformBitmap?) throws -> UIImage? {
    guard let descriptor, !(descriptor.bitmap is PlatformBitmapDefaultMarker) else {
      return nil
    }
    if let image = decodedImages[descriptor] {
      return image
    }
    let source = try source(for: descriptor)
    let data: Data
    switch source.contents {
    case .asset(let asset, let package):
      let resource = lookupAsset(asset, package)
      guard let path = Bundle.main.path(forResource: resource, ofType: nil) else {
        throw amapPigeonError("marker_icon", "Unable to read map asset '\(asset)'.")
      }
      do {
        data = try Data(contentsOf: URL(fileURLWithPath: path))
      } catch {
        throw amapPigeonError("marker_icon", "Unable to read map asset '\(asset)'.")
      }
    case .bytes(let bytes):
      data = bytes
    }
    guard data.count <= Self.maximumEncodedBytes else {
      throw amapPigeonError("invalid_bitmap", "Map bitmap exceeds the 20 MiB encoded size limit.")
    }
    try validate(source)
    let scale = source.scaling == .none ? 1 : CGFloat(source.pixelRatio)
    guard let decoded = UIImage(data: data, scale: scale) else {
      throw amapPigeonError("marker_icon", "Unable to decode map bitmap.")
    }
    guard decoded.size.width.isFinite, decoded.size.height.isFinite,
      decoded.size.width * decoded.scale <= Self.maximumDimension,
      decoded.size.height * decoded.scale <= Self.maximumDimension,
      decoded.size.width * decoded.size.height * decoded.scale * decoded.scale <= Self.maximumPixels
    else {
      throw amapPigeonError("invalid_bitmap", "Decoded map bitmap is too large.")
    }
    let image = try resized(decoded, source: source)
    decodedImages[descriptor] = image
    return image
  }

  func cachedImage(for descriptor: PlatformBitmap?) -> UIImage? {
    guard let descriptor else { return nil }
    return decodedImages[descriptor]
  }

  func dispose() {
    decodedImages.removeAll()
  }

  private func source(for descriptor: PlatformBitmap) throws -> ImageSource {
    switch descriptor.bitmap {
    case let bitmap as PlatformBitmapAssetMap:
      return ImageSource(
        contents: .asset(bitmap.assetName, nil), scaling: bitmap.bitmapScaling,
        pixelRatio: bitmap.imagePixelRatio, width: bitmap.width, height: bitmap.height)
    case let bitmap as PlatformBitmapBytesMap:
      return ImageSource(
        contents: .bytes(bitmap.byteData.data), scaling: bitmap.bitmapScaling,
        pixelRatio: bitmap.imagePixelRatio, width: bitmap.width, height: bitmap.height)
    case let bitmap as PlatformBitmapAsset:
      return ImageSource(contents: .asset(bitmap.name, bitmap.pkg))
    case let bitmap as PlatformBitmapAssetImage:
      return ImageSource(
        contents: .asset(bitmap.name, nil), pixelRatio: bitmap.scale,
        width: bitmap.size?.x, height: bitmap.size?.y)
    case let bitmap as PlatformBitmapBytes:
      return ImageSource(
        contents: .bytes(bitmap.byteData.data), width: bitmap.size?.x, height: bitmap.size?.y)
    default:
      throw amapPigeonError("marker_icon", "Unsupported map bitmap descriptor.")
    }
  }

  private func validate(_ source: ImageSource) throws {
    guard source.pixelRatio.isFinite, source.pixelRatio > 0 else {
      throw amapPigeonError("invalid_bitmap", "Map bitmap pixel ratio must be finite and positive.")
    }
    for dimension in [source.width, source.height].compactMap({ $0 }) {
      guard dimension.isFinite, dimension > 0, dimension <= Self.maximumDimension else {
        throw amapPigeonError(
          "invalid_bitmap", "Map bitmap dimensions must be finite and at most 8192 points.")
      }
    }
    if let width = source.width, let height = source.height,
      width * height > Self.maximumPixels
    {
      throw amapPigeonError("invalid_bitmap", "Requested map bitmap size is too large.")
    }
  }

  private func resized(_ image: UIImage, source: ImageSource) throws -> UIImage {
    guard source.scaling == .auto else { return image }
    let original = image.size
    let target: CGSize
    let requestedWidth = source.width.map { CGFloat($0) }
    let requestedHeight = source.height.map { CGFloat($0) }
    switch (requestedWidth, requestedHeight) {
    case (let width?, let height?):
      target = CGSize(width: width, height: height)
    case (let width?, nil):
      target = CGSize(width: width, height: original.height * width / original.width)
    case (nil, let height?):
      target = CGSize(width: original.width * height / original.height, height: height)
    case (nil, nil):
      return image
    }
    guard target.width.isFinite, target.height.isFinite,
      target.width > 0, target.height > 0,
      target.width <= Self.maximumDimension, target.height <= Self.maximumDimension,
      target.width * target.height <= Self.maximumPixels
    else {
      throw amapPigeonError("invalid_bitmap", "Requested map bitmap size is invalid or too large.")
    }
    return UIGraphicsImageRenderer(size: target).image { _ in
      image.draw(in: CGRect(origin: .zero, size: target))
    }
  }
}

private enum ImageContents {
  case asset(String, String?)
  case bytes(Data)
}

private struct ImageSource {
  let contents: ImageContents
  let scaling: PlatformMapBitmapScaling
  let pixelRatio: Double
  let width: Double?
  let height: Double?

  init(
    contents: ImageContents,
    scaling: PlatformMapBitmapScaling = .auto,
    pixelRatio: Double = 1,
    width: Double? = nil,
    height: Double? = nil
  ) {
    self.contents = contents
    self.scaling = scaling
    self.pixelRatio = pixelRatio
    self.width = width
    self.height = height
  }
}
