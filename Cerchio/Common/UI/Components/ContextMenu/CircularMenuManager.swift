//
//  CircularMenuManager.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit

class CircularMenuManager {
    static let shared = CircularMenuManager()
    private init() {}
    private var currentMenuViewController: CircularMenuViewController?

    func showMenu(
        at point: CGPoint,
        selectedView: UIView,
        items: [CircularMenuItemProtocol],
        from presentingViewController: UIViewController,
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        let menuVC = CircularMenuViewController()
        menuVC.modalPresentationStyle = .overFullScreen
        menuVC.modalTransitionStyle = .crossDissolve

        customization?(menuVC)
        currentMenuViewController = menuVC

        presentingViewController.present(menuVC, animated: false) {
            menuVC.showMenu(at: point, selectedView: selectedView, items: items)
        }
    }

    func addLongPressMenu(
        to view: UIView,
        targetView: UIView,
        items: [CircularMenuItemProtocol],
        presentingViewController: UIViewController,
        minimumPressDuration: TimeInterval = 0.5,
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        let gestureHandler = LongPressGestureHandler(
            targetView: targetView,
            items: items,
            presentingViewController: presentingViewController,
            customization: customization
        )

        let longPress = UILongPressGestureRecognizer(target: gestureHandler, action: #selector(LongPressGestureHandler.handleGesture(_:)))
        longPress.minimumPressDuration = minimumPressDuration

        view.addGestureRecognizer(longPress)
        view.setAssociatedLongPressHandler(gestureHandler)
    }

    func addTapMenu(
        to view: UIView,
        targetView: UIView,
        items: [CircularMenuItemProtocol],
        presentingViewController: UIViewController,
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        let gestureHandler = TapGestureHandler(
            targetView: targetView,
            items: items,
            presentingViewController: presentingViewController,
            customization: customization
        )

        let tap = UITapGestureRecognizer(target: gestureHandler, action: #selector(TapGestureHandler.handleGesture(_:)))
        view.addGestureRecognizer(tap)
        view.setAssociatedTapHandler(gestureHandler)
    }

    // MARK: - Touch handling (Long Press 전용)
    func updateTouchLocation(_ location: CGPoint) {
        currentMenuViewController?.updateTouchLocation(location)
    }

    func touchEnded() {
        currentMenuViewController?.touchEnded()
        currentMenuViewController = nil
    }

    func touchCancelled() {
        currentMenuViewController?.touchCancelled()
        currentMenuViewController = nil
    }
}
