import CoreGraphics
import UIKit

class ShapeCommand: BaseCommand {

    // MARK: - fields

    private let color: UIColor
    private let width: CGFloat
    private let p0: CGPoint
    private let p1: CGPoint
    private let instrument: Instrument
    private let preview: Bool

    // MARK: - init

    init(id: UInt32, canvas: CanvasView?, color: UIColor, width: CGFloat, p0: CGPoint, p1: CGPoint, instrument: Instrument, preview: Bool) {
        self.color = color
        self.width = width
        self.p0 = p0
        self.p1 = p1
        self.instrument = instrument
        self.preview = preview
        super.init(id: id, canvas: canvas)
    }

    // MARK: - private methods

    private func drawLine(withArrow: Bool) -> (strokePath: CGMutablePath?, fillPath: CGMutablePath?) {
        let strokePath = CGMutablePath()
        strokePath.move(to: p0)
        strokePath.addLine(to: p1)

        var fillPath: CGMutablePath?

        if withArrow {
            let anchorPoint = p1

            let dx = p1.x - p0.x
            let dy = p1.y - p0.y
            let radians = atan2(-dx, dy)

            var transform = CGAffineTransform(translationX: anchorPoint.x, y: anchorPoint.y)
            transform = transform.rotated(by: radians)
            transform = transform.translatedBy(x: -anchorPoint.x, y: -anchorPoint.y)

            let arrowHalfW = width * 2
            let arrowHalfH = width * 1.5

            let lbp = CGPoint(x: anchorPoint.x - arrowHalfW, y: anchorPoint.y - arrowHalfH)
            let rbp = CGPoint(x: anchorPoint.x + arrowHalfW, y: anchorPoint.y - arrowHalfH)
            let tp = CGPoint(x: anchorPoint.x, y: anchorPoint.y + arrowHalfH)

            fillPath = CGMutablePath()
            fillPath?.addLines(between: [lbp, rbp, tp], transform: transform)
        }

        return (strokePath, fillPath)
    }

    private func drawCircle() -> (strokePath: CGMutablePath?, fillPath: CGMutablePath?) {
        let strokePath = CGMutablePath()

        let centerY = (p0.y + p1.y) / 2
        let centerX = (p0.x + p1.x) / 2
        let center = CGPoint(x: centerX, y: centerY)
        let radius = hypot(p0.y - centerY, p0.x - centerX)

        strokePath.addPath(UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true).cgPath)

        return (strokePath, nil)
    }

    private func drawTriangle() -> (strokePath: CGMutablePath?, fillPath: CGMutablePath?) {
        let dist = p0.distanceTo(p1: p1)
        let angle = p0.angleTo(p1: p1)

        let strokePath = CGMutablePath()
        strokePath.move(to: CGPoint(x: p0.x - dist / 2, y: p0.y))
        strokePath.addLine(to: CGPoint(x: p0.x, y: p0.y + dist))
        strokePath.addLine(to: CGPoint(x: p0.x + dist / 2, y: p0.y))
        strokePath.closeSubpath()

        let center = CGPoint(x: p0.x, y: p0.y + dist / 2)

        var rotationTransform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: angle)
            .translatedBy(x: -center.x, y: -center.y)

        let rotatedPath = CGMutablePath()
        rotatedPath.addPath(strokePath.copy(using: &rotationTransform)!)

        return (rotatedPath, nil)
    }

    private func drawSquare() -> (strokePath: CGMutablePath?, fillPath: CGMutablePath?) {
        let strokePath = CGMutablePath()

        let x0 = p0.x
        let y0 = p0.y
        let x1 = p1.x
        let y1 = p1.y

        // center point
        let xc = (x0 + x1) / 2
        let yc = (y0 + y1) / 2

        // half-diagonal
        let xd = (x0 - x1) / 2
        let yd = (y0 - y1) / 2

        // other two corners
        let x2 = xc - yd
        let y2 = yc + xd
        let x3 = xc + yd
        let y3 = yc - xd

        strokePath.move(to: CGPoint(x: x0, y: y0))
        strokePath.addLine(to: CGPoint(x: x2, y: y2))
        strokePath.addLine(to: CGPoint(x: x1, y: y1))
        strokePath.addLine(to: CGPoint(x: x3, y: y3))
        strokePath.closeSubpath()

        return (strokePath, nil)
    }

    // MARK: - overridden methods

    override func execute() -> Bool {
        guard let canvas = canvas else { return false }

        let layer = createDrawLayer()

        if preview {
            canvas.previewLayer = layer
        } else {
            canvas.addLayer(layer)
        }
        canvas.setNeedsDisplay()

        return true
    }

    override func cancel() -> Bool {
        guard let canvas = canvas else { return false }

        if preview {
            if canvas.clearPreviewLayer() {
                canvas.setNeedsDisplay()
                return true
            }
            return false
        }

        if canvas.removeLayer(commandId: id) {
            canvas.setNeedsDisplay()
            return true
        }

        return false
    }

    // MARK: - public methods

    func createDrawLayer() -> DrawLayer {
        var draw: (strokePath: CGMutablePath?, fillPath: CGMutablePath?)

        switch instrument {
        case .pencil:
            break
        case .brush:
            break
        case .line:
            draw = drawLine(withArrow: false)
        case .arrow:
            draw = drawLine(withArrow: true)
        case .circle:
            draw = drawCircle()
        case .triangle:
            draw = drawTriangle()
        case .square:
            draw = drawSquare()
        }

        return DrawLayer(commandId: id, strokePath: draw.strokePath, fillPath: draw.fillPath, color: color, width: width)
    }
}
