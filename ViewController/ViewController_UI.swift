import UIKit

extension ViewController {

    // MARK: - private methods

    private func getImage(_ name: String, _ tint: Bool = true) -> UIImage? {
        var img = UIImage.init(named: name)?.withRenderingMode(.alwaysOriginal)

        if tint {
            img = img?.withTintColor(UIColor(named: "tintColor")!)
        }

        return img
    }

    private func getSystemImage(_ name: String, tint: Bool = true, weight: UIImage.SymbolWeight = .light) -> UIImage? {
        var img = UIImage(systemName: name)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 26, weight: weight))
            .withRenderingMode(.alwaysOriginal)

        if tint {
            img = img?.withTintColor(UIColor(named: "tintColor")!)
        }

        return img
    }

    private func getButton(_ img: UIImage?) -> UIButton {
        let btn = UIButton()
        btn.setImage(img, for: .normal)
        btn.setImage(img?.withTintColor(.inchWorm), for: .selected)
        return btn
    }

    private func selectShapeBtn() {
        pencilBtn.isSelected = false
        panBtn.isSelected = false
        eraserBtn.isSelected = false
        shapeBtn.isSelected = true
    }

    private func selectShape(_ instrument: Instrument) {
        canvas.drawColor = drawColor
        canvas.drawWidth = pencilWidth
        selectShapeBtn()
        canvasScrollView.panGestureRecognizer.isEnabled = false
        canvasScrollView.pinchGestureRecognizer?.isEnabled = false
        canvas.isUserInteractionEnabled = true
        canvas.instrument = instrument
    }

    // MARK: - public methods

    func hideUnhideToolsForAnimator(_ hide: Bool) {
        undoBtn.isHidden = hide
        redoBtn.isHidden = hide
        binBtn.isHidden = hide
        addFrameBtn.isHidden = hide
        framesBtn.isHidden = hide
        if framesBtn.isSelected {
            framesSlider.isHidden = hide
        }
        widthBtn.isHidden = hide
        pencilBtn.isHidden = hide
        panBtn.isHidden = hide
        eraserBtn.isHidden = hide
        shapeBtn.isHidden = hide
        colorBtn.isHidden = hide
        moreBtn.isHidden = hide

        swipeBack.isEnabled = !hide
        swipeForth.isEnabled = !hide

        shareBtn.isHidden = !hide
        speedSlider.isHidden = !hide
    }

    func setPlayBtnEnabled(_ enabled: Bool) {
        playBtn.isEnabled = enabled
        pauseBtn.isEnabled = !enabled
    }

    func presentColorPicker() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.title = "Choose Color"
        colorPicker.delegate = self
        colorPicker.modalPresentationStyle = .popover
        self.present(colorPicker, animated: true)
    }

    func updateColorBtnMenu() {
        var actions = colors.enumerated().map { _, color in
            UIAction(title: "", image: UIImage(systemName: "circle.fill")?
                .withTintColor(color)
                .withRenderingMode(.alwaysOriginal)) { [weak self] _ in
                    guard let self = self else { return }
                    self.onNewColorPicked(color)
                }
        }

        actions.insert(UIAction(title: "From palette", image: UIImage(systemName: "paintpalette")) { [weak self] _ in
            guard let self = self else { return }
            self.presentColorPicker()
        }, at: 0)

        colorBtn.menu = UIMenu(title: "", children: actions)
    }

    func updatePlayBtnIsEnabled() {
        playBtn.isEnabled = frames.count > 1
    }

    func showNumberInputDialog(_ title: String, completion: @escaping (Int?) -> Void) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
        }

        let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let text = alertController.textFields?.first?.text, let number = Int(text) {
                completion(number)
            } else {
                completion(nil)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func showError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)

        present(alertController, animated: true, completion: nil)
    }

    func invalidateFramesSlider() {
        framesSlider.maximumValue = Float(framesCount - 1)
        framesSlider.value = Float(currentFrameIndex)
        framesSlider.setNeedsDisplay()
    }

    func getSliderThumb(_ w: CGFloat, _ h: CGFloat) -> UIImage {
        let thumb = UIView()
        thumb.backgroundColor = .inchWorm.withAlphaComponent(0.5)
        thumb.setSize(w, h)
        return thumb.asImage()
    }

    func createMoreBtnMenu() -> UIMenu {
        UIMenu(title: "", children: [
            UIAction(title: brushMode ? "Activate pencil" : "Activate brush", 
                     image: UIImage(named: brushMode ? "brush" : "pencil")?.withTintColor(UIColor(named: "tintColor")!)) { [weak self] _ in
                guard let self = self else { return }

                brushMode = !brushMode
                if brushMode {
                    canvas.instrument = .brush
                } else {
                    canvas.instrument = .pencil
                }

                let img = getImage(brushMode ? "brush" : "pencil")
                pencilBtn.setImage(img, for: .normal)
                pencilBtn.setImage(img?.withTintColor(.inchWorm), for: .selected)
                moreBtn.menu = createMoreBtnMenu()
            },
            UIAction(title: "Remove all frames", image: UIImage(systemName: "xmark")?.withTintColor(.red).withRenderingMode(.alwaysOriginal), attributes: [.destructive]) { [weak self] _ in
                guard let self = self else { return }
                self.removeAllFrames()
            },
            UIAction(title: "Duplicate frame", image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                guard let self = self else { return }
                self.duplicateFrame()
            },
            UIAction(title: "Generate frames", image: UIImage(systemName: "sparkles")?.withTintColor(.sunglow).withRenderingMode(.alwaysOriginal)) { [weak self] _ in
                guard let self = self else { return }
                self.showNumberInputDialog("Enter frames count") { [weak self] number in
                    guard let self = self else { return }
                    if let number = number {
                        if number > 0 {
                            self.generateRandomFrames(number)
                        } else {
                            self.showError(message: "Entered count is not supported")
                        }
                    }
                }
            }
        ])
    }

    // MARK: - overridden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(named: "bgColor")

        canvasImV = UIImageView()
        canvasImV.layer.masksToBounds = true
        canvasImV.layer.cornerRadius = radius
        canvasImV.image = UIImage(named: "canvas")
        view.addSubview(canvasImV)

        canvasScrollView = UIScrollView()
        canvasScrollView.delaysContentTouches = false
        canvasScrollView.panGestureRecognizer.isEnabled = false
        canvasScrollView.pinchGestureRecognizer?.isEnabled = false
        canvasScrollView.delegate = self
        canvasScrollView.minimumZoomScale = 1.0
        canvasScrollView.maximumZoomScale = 3.0
        view.addSubview(canvasScrollView)

        canvascontainerView = UIView()
        canvasScrollView.addSubview(canvascontainerView)

        previousFrameImV = UIImageView()
        previousFrameImV.alpha = 0.5
        previousFrameImV.layer.masksToBounds = true
        previousFrameImV.layer.cornerRadius = radius
        canvascontainerView.addSubview(previousFrameImV)

        canvas = CanvasView()
        canvas.delegate = self
        canvas.drawWidth = pencilWidth
        canvas.drawColor = drawColor
        canvas.layer.masksToBounds = true
        canvas.layer.cornerRadius = radius
        canvas.backgroundColor = .clear
        canvascontainerView.addSubview(canvas)

        frameNumLabel = UILabel()
        frameNumLabel.font = UIFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        frameNumLabel.textColor = UIColor(named: "tintColor")
        updateFrameNumLabel()
        view.addSubview(frameNumLabel)

        animator = AnimatorView()
        animator.delegate = self
        animator.isHidden = true
        view.addSubview(animator)

        undoBtn = getButton(getImage("undo"))
        undoBtn.isEnabled = false
        undoBtn.addTarget(self, action: #selector(undoBtnHandler), for: .touchUpInside)
        view.addSubview(undoBtn)

        redoBtn = getButton(getImage("redo"))
        redoBtn.isEnabled = false
        redoBtn.addTarget(self, action: #selector(redoBtnHandler), for: .touchUpInside)
        view.addSubview(redoBtn)

        binBtn = getButton(getImage("bin"))
        binBtn.addTarget(self, action: #selector(binBtnHandler), for: .touchUpInside)
        view.addSubview(binBtn)

        addFrameBtn = getButton(getImage("filePlus"))
        addFrameBtn.addTarget(self, action: #selector(addBtnHandler), for: .touchUpInside)
        view.addSubview(addFrameBtn)

        framesBtn = getButton(getImage("layers"))
        framesBtn.addTarget(self, action: #selector(framesBtnHandler), for: .touchUpInside)
        view.addSubview(framesBtn)

        widthBtn = getButton(getSystemImage("scribble.variable"))
        widthBtn.addTarget(self, action: #selector(widthBtnHandler), for: .touchUpInside)
        view.addSubview(widthBtn)

        pencilBtn = getButton(getImage("pencil"))
        pencilBtn.isSelected = true
        pencilBtn.addTarget(self, action: #selector(pencilBtnHandler), for: .touchUpInside)
        view.addSubview(pencilBtn)

        panBtn = getButton(getSystemImage("hand.point.up.left"))
        panBtn.addTarget(self, action: #selector(panBtnHandler), for: .touchUpInside)
        view.addSubview(panBtn)

        eraserBtn = getButton(getImage("eraser"))
        eraserBtn.addTarget(self, action: #selector(eraserBtnHandler), for: .touchUpInside)
        view.addSubview(eraserBtn)

        shapeBtn = getButton(getImage("shape"))
        shapeBtn.menu = UIMenu(title: "", children: [
            UIAction(title: "Square", image: UIImage(systemName: "square")) { [weak self] _ in
                guard let self = self else { return }
                self.selectShape(.square)
            },
            UIAction(title: "Triangle", image: UIImage(systemName: "triangle")) { [weak self] _ in
                guard let self = self else { return }
                self.selectShape(.triangle)
            },
            UIAction(title: "Circle", image: UIImage(systemName: "circle")) { [weak self] _ in
                guard let self = self else { return }
                self.selectShape(.circle)
            },
            UIAction(title: "Arrow", image: UIImage(systemName: "line.diagonal.arrow")) { [weak self] _ in
                guard let self = self else { return }
                self.selectShape(.arrow)
            },
            UIAction(title: "Line", image: UIImage(systemName: "line.diagonal")) { [weak self] _ in
                guard let self = self else { return }
                self.selectShape(.line)
            }
        ])
        shapeBtn.showsMenuAsPrimaryAction = true
        view.addSubview(shapeBtn)

        colorBtn = getButton(getSystemImage("circle.fill", tint: false))
        colorBtn.showsMenuAsPrimaryAction = true
        colorBtn.imageView?.tintColor = drawColor
        updateColorBtnMenu()
        view.addSubview(colorBtn)

        moreBtn = getButton(getSystemImage("ellipsis.circle"))
        moreBtn.menu = createMoreBtnMenu()
        moreBtn.showsMenuAsPrimaryAction = true
        moreBtn.imageView?.tintColor = .white
        view.addSubview(moreBtn)

        shareBtn = getButton(getSystemImage("square.and.arrow.up"))
        shareBtn.isHidden = true
        shareBtn.addTarget(self, action: #selector(shareBtnHandler), for: .touchUpInside)
        view.addSubview(shareBtn)

        pauseBtn = getButton(getImage("pause"))
        pauseBtn.isEnabled = false
        pauseBtn.addTarget(self, action: #selector(pauseBtnHandler), for: .touchUpInside)
        view.addSubview(pauseBtn)

        playBtn = getButton(getImage("play"))
        playBtn.isEnabled = false
        playBtn.addTarget(self, action: #selector(playBtnHandler), for: .touchUpInside)
        view.addSubview(playBtn)

        speedSlider = UISlider()
        speedSlider.tintColor = .inchWorm
        speedSlider.isHidden = true
        speedSlider.isContinuous = false
        speedSlider.minimumValue = AppConfig.minimumSpeedInterval
        speedSlider.maximumValue = AppConfig.maximumSpeedInterval
        speedSlider.value = AppConfig.initialSpeedInterval
        speedSlider.addTarget(self, action: #selector(speedSliderValueChanged(_:)), for: .valueChanged)
        view.addSubview(speedSlider)

        swipeBack = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeBack.edges = .left
        view.addGestureRecognizer(swipeBack)

        swipeForth = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeForth.edges = .right
        view.addGestureRecognizer(swipeForth)

        framesSlider = FramesSlider()
        framesSlider.delegate = self
        framesSlider.isHidden = true
        framesSlider.minimumValue = 0
        framesSlider.minimumTrackTintColor = .clear
        framesSlider.maximumTrackTintColor = .clear
        framesSlider.addTarget(self, action: #selector(framesSliderValueChanged(_:)), for: .valueChanged)
        framesSlider.setThumbImage(getSliderThumb(framesSliderThumbW, framesSliderH), for: .normal)
        invalidateFramesSlider()
        view.addSubview(framesSlider)

        dummyView = DummyView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var topMargin: CGFloat = view.safeAreaInsets.top + margin

        addFrameBtn.sizeToFit()
        addFrameBtn.centerHorizontallyInView(view)
        addFrameBtn.setTop(topMargin)

        undoBtn.sizeToFit()
        let undoBtnAdditionalTopMargin = (addFrameBtn.frame.height - undoBtn.frame.height) / 2
        undoBtn.move(margin, topMargin + undoBtnAdditionalTopMargin)

        redoBtn.sizeToFit()
        redoBtn.move(undoBtn.frame.maxX + margin / 2, topMargin + undoBtnAdditionalTopMargin)

        binBtn.sizeToFit()
        binBtn.move(addFrameBtn.frame.minX - margin - binBtn.frame.width, addFrameBtn.frame.minY)

        framesBtn.sizeToFit()
        framesBtn.move(addFrameBtn.frame.maxX + margin, addFrameBtn.frame.minY)

        topMargin = addFrameBtn.frame.maxY + margin

        let bottomMargin = view.safeAreaInsets.bottom + margin
        let height = view.frame.height
        let width = view.frame.width

        canvasImV.setSize(width - 2 * margin, height - 2 * topMargin)
        canvasImV.move(margin, topMargin)

        canvasScrollView.frame = canvasImV.frame
        animator.frame = canvasImV.frame
        previousFrameImV.frame = canvasImV.frame

        canvascontainerView.setSize(canvasImV.frame.width * canvasScrollView.zoomScale, canvasImV.frame.height * canvasScrollView.zoomScale)
        previousFrameImV.frame = canvascontainerView.bounds
        canvas.frame = canvascontainerView.bounds

        frameNumLabel.sizeToFit()
        frameNumLabel.move(margin, canvasImV.frame.maxY + 10)

        eraserBtn.sizeToFit()
        eraserBtn.centerHorizontallyInView(view)
        eraserBtn.setTop(height - bottomMargin - eraserBtn.frame.height)

        widthBtn.sizeToFit()
        widthBtn.move(margin, eraserBtn.frame.minY)

        shapeBtn.sizeToFit()
        shapeBtn.move(eraserBtn.frame.maxX + margin, eraserBtn.frame.minY)

        panBtn.sizeToFit()
        panBtn.move(eraserBtn.frame.minX - margin - panBtn.frame.width, eraserBtn.frame.minY)

        pencilBtn.sizeToFit()
        pencilBtn.move(panBtn.frame.minX - margin - pencilBtn.frame.width, eraserBtn.frame.minY)

        colorBtn.sizeToFit()
        colorBtn.move(shapeBtn.frame.maxX + margin, eraserBtn.frame.minY)

        moreBtn.sizeToFit()
        moreBtn.move(width - moreBtn.frame.width - margin, eraserBtn.frame.minY)

        shareBtn.sizeToFit()
        shareBtn.move(margin, addFrameBtn.frame.minY)

        playBtn.sizeToFit()
        playBtn.move(width - margin - playBtn.frame.width, addFrameBtn.frame.minY)

        pauseBtn.sizeToFit()
        pauseBtn.move(playBtn.frame.minX - margin / 2 - pauseBtn.frame.width, addFrameBtn.frame.minY)

        speedSlider.sizeToFit()
        speedSlider.setWidth(canvasImV.frame.width)
        speedSlider.move(margin, eraserBtn.frame.minY)

        framesSlider.setWidth(canvasImV.frame.width)
        framesSlider.setHeight(framesSliderH)
        framesSlider.move(margin, canvasImV.frame.maxY - framesSlider.frame.height)
        let framesSliderPath = UIBezierPath(roundedRect: framesSlider.bounds,
                                            byRoundingCorners: [.bottomLeft, .bottomRight],
                                            cornerRadii: CGSize(width: radius, height: radius))
        let framesSlidermask = CAShapeLayer()
        framesSlidermask.path = framesSliderPath.cgPath
        framesSlider.layer.mask = framesSlidermask

        dummyView.frame = view.bounds
    }
}
