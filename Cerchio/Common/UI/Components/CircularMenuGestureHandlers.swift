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
    private let customization: ((CircularMenuViewController) -> Void)?

    init(targetView: UIView, items: [CircularMenuItemProtocol], presentingViewController: UIViewController, customization: ((CircularMenuViewController) -> Void)? = nil) {
        self.targetView = targetView
        self.items = items
        self.presentingViewController = presentingViewController
        self.customization = customization
        super.init()
    }

    @objc func handleGesture(_ gesture: UILongPressGestureRecognizer) {
        guard let presentingVC = presentingViewController else { return }
        let point = gesture.location(in: presentingVC.view)

        switch gesture.state {
        case .began:
            CircularMenuManager.shared.showMenu(
                at: point,
                selectedView: targetView,
                items: items,
                from: presentingVC,
                customization: customization
            )

        case .changed:
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
        let point = gesture.location(in: presentingVC.view)

        let tapMenuVC = TapMenuViewController()
        tapMenuVC.modalPresentationStyle = .overFullScreen
        tapMenuVC.modalTransitionStyle = .crossDissolve

        customization?(tapMenuVC)

        presentingVC.present(tapMenuVC, animated: false) {
            tapMenuVC.showMenu(at: point, selectedView: self.targetView, items: self.items)
        }
    }
}