import CoreGraphics
import UIKit

class BaseLayer {
    let commandId: UInt32

    init(commandId: UInt32) {
        self.commandId = commandId
    }

    func draw(context: CGContext) {
        fatalError("Must override")
    }
}
