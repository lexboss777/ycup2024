import UIKit

extension ViewController {
    @objc func undoBtnHandler(sender: UIButton!) {
        if !undoStack.isEmpty {
            let command = undoStack.removeLast()
            _ = command.cancel()
            redoStack.append(command)
            onCommandStackChanged()
        }
    }

    @objc func redoBtnHandler(sender: UIButton!) {
        if !redoStack.isEmpty {
            let command = redoStack.removeLast()
            _ = command.execute()
            undoStack.append(command)
            onCommandStackChanged()
        }
    }

    @objc func binBtnHandler(sender: UIButton!) {
        let frame = frames.remove(at: currentFrameIndex)
        Storage.removeImage(of: frame)

        if currentFrameIndex >= frames.count {
            currentFrameIndex -= 1
        }

        if frames.isEmpty {
            currentFrameIndex = -1
            _ = addNewFrame()
        }

        onFramesChanged()
    }

    @objc func addBtnHandler(sender: UIButton!) {
        saveCurrentFrameToFile()
        _ = addNewFrame()
        onFramesChanged()
    }

    @objc func framesBtnHandler(sender: UIButton!) {
        framesBtn.isSelected = !framesBtn.isSelected
        framesSlider.isHidden = !framesSlider.isHidden
        if !framesSlider.isHidden {
            framesSlider.setNeedsDisplay()
        }
    }

    @objc func widthBtnHandler(sender: UIButton!) {
        dummyView.clear()

        let chooseWidthView = ChooseWidthView()
        chooseWidthView.width = canvas.drawWidth
        chooseWidthView.color = drawColor

        chooseWidthView.sizeToFit()
        chooseWidthView.setWidth(dummyView.frame.width - 2 * margin)
        chooseWidthView.centerInView(dummyView)

        dummyView.show(on: view, viewToShow: chooseWidthView, actionOnTouches: { [weak self] in
            guard let self else { return }
            dummyView.hide()

            if eraserBtn.isSelected {
                eraserWidth = CGFloat(chooseWidthView.width)
                canvas.drawWidth = eraserWidth
            } else {
                pencilWidth = CGFloat(chooseWidthView.width)
                canvas.drawWidth = pencilWidth
            }
        })
    }

    @objc func eraserBtnHandler(sender: UIButton!) {
        pencilBtn.isSelected = false
        panBtn.isSelected = false
        eraserBtn.isSelected = true
        shapeBtn.isSelected = false
        canvasScrollView.panGestureRecognizer.isEnabled = false
        canvasScrollView.pinchGestureRecognizer?.isEnabled = false
        canvas.isUserInteractionEnabled = true
        canvas.drawColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        canvas.drawWidth = eraserWidth
        canvas.instrument = .pencil
    }

    @objc func pencilBtnHandler(sender: UIButton!) {
        pencilBtn.isSelected = true
        panBtn.isSelected = false
        eraserBtn.isSelected = false
        shapeBtn.isSelected = false
        canvasScrollView.panGestureRecognizer.isEnabled = false
        canvasScrollView.pinchGestureRecognizer?.isEnabled = false
        canvas.isUserInteractionEnabled = true
        canvas.drawColor = drawColor
        canvas.drawWidth = pencilWidth
        canvas.instrument = brushMode ? .brush : .pencil
    }

    @objc func panBtnHandler(sender: UIButton!) {
        pencilBtn.isSelected = false
        panBtn.isSelected = true
        eraserBtn.isSelected = false
        shapeBtn.isSelected = false
        canvasScrollView.panGestureRecognizer.isEnabled = true
        canvasScrollView.pinchGestureRecognizer?.isEnabled = true
        canvas.isUserInteractionEnabled = false
    }

    @objc func shareBtnHandler(sender: UIButton!) {
        animator.stop()

        var images: [UIImage] = []
        for frame in frames {
            if let image = UIImage(contentsOfFile: Storage.getFrameImagePath(frame.uuid)) {
                images.append(image)
            }
        }

        if !images.isEmpty {
            let url = Storage.getDocumentsDirectory().appendingPathComponent("\(AppConfig.awesomeWords.randomElement()!).gif")
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if GifCreator.create(with: images, delay: Double(speedSlider.value), filePath: url.path) {
                    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    present(activityViewController, animated: true, completion: nil)
                }
            }
        }
    }

    @objc func pauseBtnHandler(sender: UIButton!) {
        setPlayBtnEnabled(true)
        hideUnhideToolsForAnimator(false)
        previousFrameImV.isHidden = false
        canvas.isHidden = false
        animator.isHidden = true
        animator.stop()
        updateFrameNumLabel()
    }

    @objc func playBtnHandler(sender: UIButton!) {
        setPlayBtnEnabled(false)
        saveCurrentFrameToFile()
        hideUnhideToolsForAnimator(true)
        previousFrameImV.isHidden = true
        canvas.isHidden = true
        animator.isHidden = false
        animator.start()
    }

    @objc func speedSliderValueChanged(_ sender: UISlider) {
        animator.setTimeInterval(Double(speedSlider.maximumValue - speedSlider.value))
    }

    @objc func framesSliderValueChanged(_ sender: UISlider) {
        let roundedValue = Int(sender.value.rounded())

        if roundedValue != currentFrameIndex {
            saveCurrentFrameToFile()
            currentFrameIndex = roundedValue
            invalidateCurrentFrame()
        }
    }

    @objc func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state != .ended {
            return
        }

        if gesture.edges == .left {
            if currentFrameIndex > 0 {
                saveCurrentFrameToFile()
                currentFrameIndex -= 1
                onFramesChanged()
            }
        } else if gesture.edges == .right {
            if currentFrameIndex + 1 < frames.count {
                saveCurrentFrameToFile()
                currentFrameIndex += 1
                onFramesChanged()
            }
        }
    }
}
