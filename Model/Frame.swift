import Foundation

struct Frame {
    var uuid: String

    var imageURL: URL {
        return Storage.getFrameImageURL(uuid)
    }

    var imagePath: String {
        return Storage.getFrameImagePath(uuid)
    }

    static func new() -> Frame {
        return Frame(uuid: UUID().uuidString)
    }
}
