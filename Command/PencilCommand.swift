import CoreGraphics
import UIKit

class PencilCommand: BaseCommand {

    // MARK: - fields

    private let color: UIColor
    private let width: CGFloat
    private var segments: [(CGPoint, CGPoint)]

    // MARK: - init

    init(id: UInt32, canvas: CanvasView, color: UIColor, width: CGFloat, p0: CGPoint, p1: CGPoint) {
        self.color = color
        self.width = width
        self.segments = [(p0, p1)]
        super.init(id: id, canvas: canvas)
    }

    // MARK: - private methods

    private func getPath() -> CGMutablePath {
        let path = CGMutablePath()

        for i in 0..<segments.count {
            let subpath = getPath(segmentIndex: i)
            path.addPath(subpath)
        }

        return path
    }

    private func getPath(segmentIndex: Int) -> CGPath {
        let (p0, p1) = segments[segmentIndex]

        let (previousPoint0, previousPoint1): (CGPoint, CGPoint)

        if segmentIndex > 0 {
            let (prevP0, prevP1) = segments[segmentIndex - 1]
            previousPoint0 = prevP0
            previousPoint1 = prevP1
        } else {
            previousPoint0 = p0
            previousPoint1 = p0
        }

        let mid0 = midPoint(previousPoint0, previousPoint1)
        let mid1 = midPoint(p1, previousPoint1)

        let subpath = CGMutablePath()
        subpath.move(to: mid0)
        subpath.addQuadCurve(to: mid1, control: previousPoint1)

        return subpath
    }

    private func midPoint(_ p0: CGPoint, _ p1: CGPoint) -> CGPoint {
        return CGPoint(x: (p0.x + p1.x) * 0.5, y: (p0.y + p1.y) * 0.5)
    }

    // MARK: - overridden methods

    override func execute() -> Bool {
        guard let canvas = canvas else { return false}
        let path = getPath()
        let layer = createDrawLayer(strokePath: path)

        canvas.addLayer(layer)
        canvas.setNeedsDisplay()

        return true
    }

    override func cancel() -> Bool {
        guard let canvas = canvas else { return false }

        if canvas.removeLayer(commandId: id) {
            canvas.setNeedsDisplay()
            return true
        }

        return false
    }

    // MARK: - public methods

    func tryToAddSegment(p0: CGPoint, p1: CGPoint) -> Bool {
        let lastPoint = segments.last!.1

        guard lastPoint.x == p0.x && lastPoint.y == p0.y else {
            return false
        }
        guard let canvas = canvas else { return false }

        segments.append((p0, p1))

        guard let drawLayer = canvas.getLayer(commandId: id) as? DrawLayer else { return false }

        let subpath = getPath(segmentIndex: segments.count - 1)
        drawLayer.strokePath!.addPath(subpath)

        canvas.setNeedsDisplay()

        return true
    }

    func createDrawLayer(strokePath: CGMutablePath) -> DrawLayer {
        return DrawLayer(commandId: id, strokePath: strokePath, fillPath: nil, color: color, width: width)
    }
}
