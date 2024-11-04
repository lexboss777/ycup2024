import UIKit
import ImageIO
import MobileCoreServices
import UniformTypeIdentifiers

class GifCreator {
    static func create(with images: [UIImage], delay: TimeInterval, filePath: String) -> Bool {
        let destinationURL = URL(fileURLWithPath: filePath)

        guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.gif.identifier as CFString, images.count, nil) else {
            return false
        }

        let properties: [NSString: Any] = [kCGImagePropertyGIFDelayTime: delay]
        CGImageDestinationSetProperties(destination, properties as CFDictionary)

        for image in images {
            guard let cgImage = image.cgImage else { continue }
            CGImageDestinationAddImage(destination, cgImage, nil)
        }

        return CGImageDestinationFinalize(destination)
    }
}
