import UIKit

extension ViewController: CanvasViewDelegate, AnimatorViewDelegate, UIColorPickerViewControllerDelegate,
                          FramesSliderDelegate, UIScrollViewDelegate {
    // MARK: - CanvasDelegate

    func newCommand(_ command: BaseCommand) {
        undoStack.append(command)
        redoStack.removeAll()
        onCommandStackChanged()
    }

    func touchesBegan() {
        canvasScrollView.panGestureRecognizer.isEnabled = false
        canvasScrollView.pinchGestureRecognizer?.isEnabled = false
    }

    // MARK: - AnimatorDelegate

    func getNextFrame(after: Int) -> (index: Int, frame: Frame?) {
        if frames.isEmpty {
            return (index: 0, frame: nil)
        }

        var newIndex = after + 1

        if newIndex >= frames.count {
            newIndex = 0
        }

        updateFrameNumLabel(newIndex + 1)

        return (index: newIndex, frame: frames[newIndex])
    }

    // MARK: - UIColorPickerViewControllerDelegate

    func colorPickerViewControllerDidFinish(_ picker: UIColorPickerViewController) {
        onNewColorPicked(picker.selectedColor)

        _ = colors.removeFirst()
        colors.append(picker.selectedColor)
        updateColorBtnMenu()
    }

    // MARK: - FramesSliderDelegate

    var framesCount: Int {
        get {
            return frames.count
        }
    }

    func getFrameImage(_ index: Int) -> UIImage? {
        return UIImage(contentsOfFile: frames[index].imagePath)
    }

    // MARK: - UIScrollViewDelegate

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return canvascontainerView
    }
}
