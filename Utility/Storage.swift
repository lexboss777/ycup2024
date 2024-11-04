import Foundation

class Storage {

    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    static func getFramesDirectory() -> URL {
        let documentsDirectory = getDocumentsDirectory()
        return documentsDirectory.appendingPathComponent("frames")
    }

    static func getFrameImageURL(_ uuid: String) -> URL {
        return Storage.getFramesDirectory().appendingPathComponent("\(uuid).png")
    }

    static func getFrameImagePath(_ uuid: String) -> String {
        return getFrameImageURL(uuid).path
    }

    static func removeImage(of: Frame) {
        if FileManager.default.fileExists(atPath: of.imagePath) {
            try? FileManager.default.removeItem(atPath: of.imagePath)
        }
    }

    static func setup() {
        let framesDirectory = getFramesDirectory()
        try? FileManager.default.removeItem(at: framesDirectory)
        try! FileManager.default.createDirectory(at: framesDirectory, withIntermediateDirectories: true, attributes: nil)
    }
}
