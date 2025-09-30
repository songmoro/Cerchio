//
//  CircularMenuGestureHandlers.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit
import ObjectiveC

extension UIView {
    struct AssociatedKeys {
        static var longPressHandler: UInt8 = 0
        static var tapHandler: UInt8 = 0
    }

    func setAssociatedLongPressHandler(_ handler: LongPressGestureHandler) {
        objc_setAssociatedObject(self, &AssociatedKeys.longPressHandler, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func getAssociatedLongPressHandler() -> LongPressGestureHandler? {
        return objc_getAssociatedObject(self, &AssociatedKeys.longPressHandler) as? LongPressGestureHandler
    }

    func setAssociatedTapHandler(_ handler: TapGestureHandler) {
        objc_setAssociatedObject(self, &AssociatedKeys.tapHandler, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func getAssociatedTapHandler() -> TapGestureHandler? {
        return objc_getAssociatedObject(self, &AssociatedKeys.tapHandler) as? TapGestureHandler
    }
}

class LongPressGestureHandler: NSObject {
    private let targetView: UIView
    private let items: [CircularMenuItemProtocol]
    private weak var presentingViewController: UIViewController?
    private let highlightConfiguration: ViewHighlightConfiguration
    private let customization: ((CircularMenuViewController) -> Void)?

    init(
        targetView: UIView,
        items: [CircularMenuItemProtocol],
        presentingViewController: UIViewController,
        highlightConfiguration: ViewHighlightConfiguration = .withContextualRotation(),
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        self.targetView = targetView
        self.items = items
        self.presentingViewController = presentingViewController
        self.highlightConfiguration = highlightConfiguration
        self.customization = customization
        super.init()
    }

    @objc func handleGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let presentingVC = presentingViewController else { return }

        switch gesture.state {
        case .began:
            // 실제 터치한 위치를 사용 (타겟 뷰 내에서의 터치 위치)
            let touchLocationInTarget = gesture.location(in: targetView)
            let touchLocationInPresentingView = targetView.convert(touchLocationInTarget, to: presentingVC.view)

            CircularMenuManager.shared.showMenu(
                at: touchLocationInPresentingView,
                selectedView: targetView,
                items: items,
                from: presentingVC,
                highlightConfiguration: highlightConfiguration,
                customization: customization
            )

        case .changed:
            let point = gesture.location(in: presentingVC.view)
            CircularMenuManager.shared.updateTouchLocation(point)

        case .ended:
            CircularMenuManager.shared.touchEnded()

        case .cancelled, .failed:
            CircularMenuManager.shared.touchCancelled()

        default:
            break
        }
    }
}

class TapGestureHandler: NSObject {
    private let targetView: UIView
    private let items: [CircularMenuItemProtocol]
    private weak var presentingViewController: UIViewController?
    private let customization: ((CircularMenuViewController) -> Void)?

    init(targetView: UIView, items: [CircularMenuItemProtocol], presentingViewController: UIViewController, customization: ((CircularMenuViewController) -> Void)? = nil) {
        self.targetView = targetView
        self.items = items
        self.presentingViewController = presentingViewController
        self.customization = customization
        super.init()
    }

    @objc func handleGesture(_ gesture: UITapGestureRecognizer) {
        guard let presentingVC = presentingViewController else { return }

        // 실제 터치한 위치를 사용 (타겟 뷰 내에서의 터치 위치)
        let touchLocationInTarget = gesture.location(in: targetView)
        let touchLocationInPresentingView = targetView.convert(touchLocationInTarget, to: presentingVC.view)

        let tapMenuVC = TapMenuViewController()
        tapMenuVC.modalPresentationStyle = .overFullScreen
        tapMenuVC.modalTransitionStyle = .crossDissolve

        customization?(tapMenuVC)

        presentingVC.present(tapMenuVC, animated: false) {
            tapMenuVC.showMenu(at: touchLocationInPresentingView, selectedView: self.targetView, items: self.items)
        }
    }
}
