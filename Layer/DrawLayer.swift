import CoreGraphics
import UIKit

class DrawLayer: BaseLayer {
    let strokePath: CGMutablePath?
    let fillPath: CGPath?
    let color: UIColor
    let width: CGFloat
    let lineCap: CGLineCap

    init(commandId: UInt32, strokePath: CGMutablePath?, fillPath: CGPath?, color: UIColor, width: CGFloat, lineCap: CGLineCap = .round) {
        self.strokePath = strokePath
        self.fillPath = fillPath
        self.color = color
        self.width = width
        self.lineCap = lineCap
        super.init(commandId: commandId)
    }

    override func draw(context: CGContext) {
        context.setLineWidth(width)
        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)
        context.setLineCap(lineCap)

        if let strokePath = strokePath {
            context.beginPath()
            context.addPath(strokePath)
            context.strokePath()
        }

        if let fillPath = fillPath {
            context.beginPath()
            context.addPath(fillPath)
            context.fillPath()
        }
    }
}
