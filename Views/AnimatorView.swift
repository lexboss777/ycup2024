import Foundation
import UIKit

protocol AnimatorViewDelegate: AnyObject {
    func getNextFrame(after: Int) -> (index: Int, frame: Frame?)
}

class AnimatorView: UIView {

    // MARK: - properties

    weak var delegate: AnimatorViewDelegate?
    var timeInterval: Double = Double(AppConfig.initialSpeedInterval)

    private var currentFrameIndex = -1
    private var currentFrameUUID: String?
    private var timer: Timer?

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

    @objc private func updateFrame() {
        guard let delegate = delegate else { return }
        let frame = delegate.getNextFrame(after: currentFrameIndex)
        currentFrameIndex = frame.index
        currentFrameUUID = frame.frame?.uuid
        setNeedsDisplay()
    }

    // MARK: - overridden methods

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if timer == nil {
            return
        }

        guard let uuid = currentFrameUUID else { return }

        let path = Storage.getFrameImagePath(uuid)

        if let image = UIImage(contentsOfFile: path) {
            image.draw(in: rect)
        }
    }

    // MARK: - public methods

    func start() {
        updateFrame()
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(updateFrame), userInfo: nil, repeats: true)
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        currentFrameIndex = -1
        setNeedsDisplay()
    }

    func setTimeInterval(_ interval: Double) {
        timeInterval = interval
        start()
    }
}
