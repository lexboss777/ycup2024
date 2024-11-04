import UIKit

class DummyView: UIView {

    // MARK: - fields

    private var backgroundImV: UIView?
    private var actionOnTouch: (() -> Void)?

    // MARK: - properties

    var showHideAnimationDuration: TimeInterval = 0.5

    var isShown: Bool {
        return !subviews.isEmpty
    }

    // MARK: - init

    init() {
        super.init(frame: .zero)
        self.alpha = 0

        backgroundImV = UIView()
        backgroundImV?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundImV?.isUserInteractionEnabled = false
        if let backgroundView = backgroundImV {
            addSubview(backgroundView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - overridden methods

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundImV?.frame = self.bounds
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if let touch = touches.first {
            let touchLocation = touch.location(in: self)
            if self.hitTest(touchLocation, with: event) == self {
                actionOnTouch?()
            }
        }
    }

    // MARK: - public methods

    func show(on viewToShowOn: UIView, viewToShow: UIView?, actionOnTouches: @escaping () -> Void, animated: Bool = true, actionOnShowAnimationCompleted: (() -> Void)? = nil) {

        if let backgroundView = backgroundImV {
            addSubview(backgroundView)
            backgroundView.frame = bounds
        }

        viewToShowOn.addSubview(self)

        if let viewToShow = viewToShow {
            addSubview(viewToShow)
        }

        actionOnTouch = actionOnTouches

        UIView.animate(withDuration: animated ? showHideAnimationDuration : 0, animations: {
            self.alpha = 1
        }, completion: { _ in
            actionOnShowAnimationCompleted?()
        })

        setNeedsLayout()
    }

    func hide(animated: Bool = true) {
        UIView.animate(withDuration: animated ? showHideAnimationDuration : 0, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.subviews.forEach { $0.removeFromSuperview() }
            self.removeFromSuperview()
        })
    }

    func clear() {
        for subView in subviews {
            if subView !== backgroundImV {
                subView.removeFromSuperview()
            }
        }
    }
}
