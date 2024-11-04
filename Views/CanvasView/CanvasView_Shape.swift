import Foundation
import UIKit

extension CanvasView {
    func drawShape(_ shapeParams: ShapeParams, preview: Bool) {
        let startPoint = shapeParams.startPoint
        let endPoint = shapeParams.endPoint ?? startPoint

        let command = ShapeCommand(id: id, canvas: self, color: drawColor, width: drawWidth, p0: startPoint, p1: endPoint, instrument: instrument, preview: preview)
        _ = command.execute()
        id += 1

        if !preview {
            delegate?.newCommand(command)
        }

        lastCommand = command
    }

    class ShapeParams {
        let startPoint: CGPoint
        var endPoint: CGPoint?

        init(x: CGFloat, y: CGFloat) {
            self.startPoint = CGPoint(x: x, y: y)
        }
    }
}
