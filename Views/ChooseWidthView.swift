import UIKit

class ChooseWidthView: UIView {

    // MARK: - declaration

    private let boxSize: CGFloat = 100
    private let margin = 16.0

    // MARK: - fields

    private let slider: UISlider!
    private let scribblePath = UIBezierPath()

    // MARK: - properties

    var width: CGFloat = 0 {
        didSet {
            slider.value = Float(width)
        }
    }

    var color: UIColor = .denim

    // MARK: - init

    init() {
        slider = UISlider()
        slider.minimumValue = AppConfig.minDrawWidth
        slider.maximumValue = AppConfig.maxDrawWidth
        slider.tintColor = .inchWorm

        super.init(frame: .zero)

        slider.addAction(for: .valueChanged) { [weak self] in
            guard let self = self else { return }

            width = CGFloat(self.slider.value)
            setNeedsDisplay()
        }

        backgroundColor = .white
        layer.cornerRadius = 20
        layer.masksToBounds = true

        addSubview(slider)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - overridden methods

    override func layoutSubviews() {
        super.layoutSubviews()

        slider.setWidth(frame.width - 2 * margin)
        slider.centerHorizontallyInView(self)
        slider.setTop(frame.height - margin - slider.frame.height)
    }

    override func sizeToFit() {
        var h = margin + boxSize

        slider.sizeToFit()
        h += margin + slider.frame.height + margin

        self.setHeight(h)
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        color.setStroke()

        let scribblePath = UIBezierPath()

        let boxOrigin = CGPoint(x: (rect.width - boxSize) / 2, y: margin)

        scribblePath.move(to: CGPoint(x: boxOrigin.x, y: boxOrigin.y + boxSize / 2))

        scribblePath.addCurve(to: CGPoint(x: boxOrigin.x + boxSize, y: boxOrigin.y + boxSize / 2),
                              controlPoint1: CGPoint(x: boxOrigin.x + boxSize * 0.3, y: boxOrigin.y),
                              controlPoint2: CGPoint(x: boxOrigin.x + boxSize * 0.7, y: boxSize))

        scribblePath.lineWidth = width
        scribblePath.stroke()
    }
}
