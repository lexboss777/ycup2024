import UIKit

class ViewController: UIViewController {

    // MARK: - declaration

    let margin = 16.0
    let radius = 20.0

    let framesSliderH = 50.0
    let framesSliderThumbW = 20.0

    // MARK: - properties

    var canvasImV: UIImageView!
    var canvasScrollView: UIScrollView!
    var canvascontainerView: UIView!
    var previousFrameImV: UIImageView!
    var canvas: CanvasView!
    var frameNumLabel: UILabel!
    var animator: AnimatorView!

    var undoBtn: UIButton!
    var redoBtn: UIButton!

    var binBtn: UIButton!
    var addFrameBtn: UIButton!
    var framesBtn: UIButton!

    var widthBtn: UIButton!
    var pencilBtn: UIButton!
    var panBtn: UIButton!
    var eraserBtn: UIButton!
    var shapeBtn: UIButton!
    var colorBtn: UIButton!
    var moreBtn: UIButton!

    var shareBtn: UIButton!
    var pauseBtn: UIButton!
    var playBtn: UIButton!
    var speedSlider: UISlider!

    var swipeBack: UIScreenEdgePanGestureRecognizer!
    var swipeForth: UIScreenEdgePanGestureRecognizer!

    var frames: [Frame] = []
    var currentFrameIndex = -1 {
        didSet {
            updateFrameNumLabel()

            undoStack.removeAll()
            redoStack.removeAll()
            onCommandStackChanged()
        }
    }

    var undoStack: [BaseCommand] = []
    var redoStack: [BaseCommand] = []

    var colors: [UIColor] = [.green, .magenta, .yellow, .denim]

    var framesSlider: FramesSlider!

    var dummyView: DummyView!

    var currentScale: CGFloat = 1.0

    var drawColor = UIColor.denim

    var pencilWidth = 5.0
    var eraserWidth = 10.0

    var brushMode = false

    // MARK: - init

    init() {
        super.init(nibName: nil, bundle: nil)
        Storage.setup()
        _ = addNewFrame()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - public methods

    func onCommandStackChanged() {
        redoBtn?.isEnabled = !redoStack.isEmpty
        undoBtn?.isEnabled = !undoStack.isEmpty
    }

    func onNewColorPicked(_ color: UIColor) {
        drawColor = color
        canvas.drawColor = drawColor
        colorBtn.imageView?.tintColor = color
    }

    func getCurrentFrame() -> Frame {
        return frames[currentFrameIndex]
    }

    func addFrame(_ frame: Frame) {
        currentFrameIndex += 1
        frames.insert(frame, at: currentFrameIndex)
    }

    func addNewFrame() -> Frame {
        let newFrame = Frame.new()
        addFrame(newFrame)
        return newFrame
    }

    func onFramesChanged() {
        updatePlayBtnIsEnabled()
        invalidateCurrentFrame()
        invalidateFramesSlider()
        updateFrameNumLabel()
    }

    func invalidateCurrentFrame() {
        let previousFrameIndex = currentFrameIndex - 1
        if previousFrameIndex >= 0 {
            previousFrameImV.image = UIImage(contentsOfFile: frames[previousFrameIndex].imagePath)
        } else {
            previousFrameImV.image = nil
        }

        canvas.image = UIImage(contentsOfFile: getCurrentFrame().imagePath)
        canvas.removeLayers()
        canvas.setNeedsDisplay()
    }

    func updateFrameNumLabel(_ num: Int? = nil) {
        let num = num ?? currentFrameIndex + 1
        frameNumLabel?.text = "\(num) / \(framesCount)"
        frameNumLabel?.sizeToFit()
    }

    func saveCurrentFrameToFile() {
        let img = canvas.asImage()
        if let data = img.pngData() {
            let frame = getCurrentFrame()
            try? data.write(to: frame.imageURL)
        }
    }

    func duplicateFrame() {
        saveCurrentFrameToFile()
        let currentFrame = getCurrentFrame()
        let newFrame = addNewFrame()

        try? FileManager.default.removeItem(atPath: newFrame.imagePath)
        try? FileManager.default.copyItem(atPath: currentFrame.imagePath, toPath: newFrame.imagePath)

        onFramesChanged()
    }

    func removeAllFrames() {
        frames.removeAll()
        Storage.setup()
        currentFrameIndex = -1
        _ = addNewFrame()

        onFramesChanged()
    }

    func generateRandomFrames(_ count: Int) {
        saveCurrentFrameToFile()

        let width = canvas.bounds.width
        let height = canvas.bounds.height
        let color = drawColor
        let drawWidth = pencilWidth
        let shapes = Instrument.allCases.filter { $0 != .pencil }

        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            for _ in 0..<count {
                autoreleasepool {
                    let frame = Frame.new()
                    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
                    let image = renderer.image { context in

                        let x0 = CGFloat.random(in: 0..<width)
                        let y0 = CGFloat.random(in: 0..<height)

                        let x1 = CGFloat.random(in: 0..<width)
                        let y1 = CGFloat.random(in: 0..<height)

                        let p0 = CGPoint(x: x0, y: y0)
                        let p1 = CGPoint(x: x1, y: y1)

                        let shape = shapes.randomElement()!

                        ShapeCommand(id: 0, canvas: nil, color: color, width: drawWidth, p0: p0, p1: p1, instrument: shape, preview: false)
                            .createDrawLayer()
                            .draw(context: context.cgContext)
                    }

                    if let data = image.pngData() {
                        try? data.write(to: frame.imageURL)
                    }

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        addFrame(frame)
                        invalidateCurrentFrame()
                    }
                }
            }

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                onFramesChanged()
            }
        }
    }
}
