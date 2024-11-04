import UIKit

protocol FramesSliderDelegate: AnyObject {
    var framesCount: Int { get }
    func getFrameImage(_ index: Int) -> UIImage?
}

class FramesSlider: UISlider {

    // MARK: - fields

    private let borderLayer = CAShapeLayer()

    // MARK: - properties

    var delegate: FramesSliderDelegate?

    // MARK: - init

    init() {
        super.init(frame: .zero)

        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.strokeColor = UIColor.sunglow.cgColor
        borderLayer.lineWidth = 4.0
        layer.addSublayer(borderLayer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - private methods

    private func drawBorder() {
        let corners: UIRectCorner = [.bottomLeft, .bottomRight]
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: 20.0, height: 20.0))

        borderLayer.path = path.cgPath
    }

    // MARK: - overridden methods

    override func layoutSubviews() {
        super.layoutSubviews()
        drawBorder()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let delegate = delegate else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.clear(rect)

        guard delegate.framesCount > 0 else { return }
        guard rect.width > 0 else { return }

        var thumbnailWidth: CGFloat = 20
        let thumbnailHeight = rect.height
        let maxDisplayCount = Int(rect.width / CGFloat(thumbnailWidth))

        let displayCount = min(maxDisplayCount, delegate.framesCount)
        thumbnailWidth = rect.width / CGFloat(displayCount)

        let pace = Float(delegate.framesCount) / Float(displayCount)

        for i in 0..<displayCount {

            let imageIndex = Int(Float(i) * pace)
            guard let image = delegate.getFrameImage(imageIndex) else { continue }

            let ratio = image.size.width / image.size.height

            let x = CGFloat(i) * thumbnailWidth + ((thumbnailWidth - thumbnailHeight * ratio) / 2)
            let thumbnailRect = CGRect(x, 0, thumbnailHeight * ratio, thumbnailHeight)

            context.saveGState()
            context.clip(to: thumbnailRect)
            image.draw(in: thumbnailRect)
            context.restoreGState()

            if AppConfig.framesSliderVerticalLine {
                UIColor.sunglow.setStroke()
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: thumbnailRect.maxX, y: 0))
                linePath.addLine(to: CGPoint(x: thumbnailRect.maxX, y: rect.height))
                linePath.lineWidth = 1.0
                linePath.stroke()
            }
        }
    }
}
