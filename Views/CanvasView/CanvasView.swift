import Foundation
import UIKit

protocol CanvasViewDelegate: AnyObject {
    func touchesBegan()
    func newCommand(_ command: BaseCommand)
}

class CanvasView: UIView {

    // MARK: - fields

    private var lastX: CGFloat = 0
    private var lastY: CGFloat = 0

    private var shapeParams: ShapeParams?

    // MARK: - properties

    var image: UIImage?

    var previewLayer: BaseLayer?

    var layers: [UInt32: BaseLayer] = [:]

    var lastCommand: BaseCommand?

    var drawColor: UIColor = .white

    var drawWidth: CGFloat = 0.0

    var id: UInt32 = 0

    var instrument: Instrument = .pencil

    let pattern = UIImage(systemName: "heart")
    var patternMinDistance: CGFloat = 20
    var lastPatternDrawPoint: CGPoint?
    var patternDrawPoint: CGPoint?

    weak var delegate: CanvasViewDelegate?

    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isOpaque = false
        clearsContextBeforeDrawing = true
    }

    // MARK: - private methods

    private func drawLayers(context: CGContext, withPreview: Bool) {
        let showPreview = withPreview && previewLayer != nil

        if layers.values.isEmpty && !showPreview {
            return
        }

        for key in layers.keys.sorted() {
            if let layer = layers[key] {
                layer.draw(context: context)
            }
        }

        if showPreview {
            previewLayer?.draw(context: context)
        }
    }

    private func drawPoint(x: CGFloat, y: CGFloat) {
        pencilDraw(x0: x, y0: y, x1: x, y1: y)
    }

    private func pencilDraw(x0: CGFloat, y0: CGFloat, x1: CGFloat, y1: CGFloat) {

        let p0 = CGPoint(x: x0, y: y0)
        let p1 = CGPoint(x: x1, y: y1)

        var command: PencilCommand?

        if let lastPencilCommand = lastCommand as? PencilCommand {
            if lastPencilCommand.tryToAddSegment(p0: p0, p1: p1) {
                command = lastPencilCommand
            }
        }

        if command == nil {
            command = PencilCommand(id: id, canvas: self, color: drawColor, width: drawWidth, p0: p0, p1: p1)
            _ = command!.execute()
            delegate?.newCommand(command!)
            id += 1
        }

        lastCommand = command
    }

    // MARK: - overridden methods

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if let context = UIGraphicsGetCurrentContext() {
            if let image = image {
                image.draw(in: rect)
            }

            context.setBlendMode(.copy)
            drawLayers(context: context, withPreview: true)

            if instrument == .brush, let point = patternDrawPoint {
                let randomAngle = CGFloat.random(in: 0...2 * .pi)
                if let pattern = pattern?.rotate(radians: randomAngle)?.withTintColor(drawColor) {
                    pattern.draw(at: CGPoint(x: point.x - pattern.size.width / 2, y: point.y - pattern.size.height))
                    self.patternDrawPoint = nil
                    self.lastPatternDrawPoint = point
                }
            }

            if instrument == .brush, let img = context.makeImage() {
                image = UIImage(cgImage: img)
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        delegate?.touchesBegan()

        lastX = point.x
        lastY = point.y

        switch instrument {
        case .pencil:
            drawPoint(x: lastX, y: lastY)
        case .brush:
            break
        default:
            shapeParams = ShapeParams(x: point.x, y: point.y)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        let newX = point.x
        let newY = point.y

        switch instrument {
        case .pencil:
            pencilDraw(x0: lastX, y0: lastY, x1: newX, y1: newY)
        case .brush:
            if lastPatternDrawPoint == nil || lastPatternDrawPoint!.distanceTo(p1: point) > patternMinDistance {
                patternDrawPoint = point
                setNeedsDisplay()
            }
        default:
            if let shapeParams = self.shapeParams {
                shapeParams.endPoint = point
                drawShape(shapeParams, preview: true)
            }
        }

        lastX = newX
        lastY = newY
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        switch instrument {
        case .pencil, .brush:
            break
        default:
            if shapeParams != nil {
                _ = clearPreviewLayer()
                shapeParams = nil
                setNeedsDisplay()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        switch instrument {
        case .pencil, .brush:
            break
        default:
            if let shapeParams = self.shapeParams {
                if shapeParams.endPoint != nil {
                    drawShape(shapeParams, preview: false)
                }
                _ = clearPreviewLayer()
                self.shapeParams = nil
                setNeedsDisplay()
            }
        }
    }

    // MARK: - public methods

    func getLayer(commandId: UInt32) -> BaseLayer? {
        if let layer = layers[commandId] {
            return layer
        }

        return nil
    }

    func addLayer(_ layer: BaseLayer) {
        layers[layer.commandId] = layer
    }

    func removeLayer(commandId: UInt32) -> Bool {
        if layers[commandId] != nil {
            layers.removeValue(forKey: commandId)
            return true
        }
        return false
    }

    func removeLayers() {
        layers.removeAll()
    }

    func clearPreviewLayer() -> Bool {
        if previewLayer == nil {
            return false
        }

        previewLayer = nil
        return true
    }
}
