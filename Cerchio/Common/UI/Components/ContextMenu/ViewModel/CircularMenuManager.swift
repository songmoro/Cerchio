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
    private var isMenuPresented: Bool = false

    func showMenu(
        at point: CGPoint,
        selectedView: UIView,
        items: [CircularMenuItemProtocol],
        from presentingViewController: UIViewController,
        highlightConfiguration: ViewHighlightConfiguration = .withContextualRotation(),
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        // 이미 메뉴가 표시 중이면 무시
        guard !isMenuPresented else {
            print("Menu is already presented, ignoring new menu request")
            return
        }

        isMenuPresented = true
        let menuVC = CircularMenuViewController()
        menuVC.modalPresentationStyle = .overFullScreen
        menuVC.modalTransitionStyle = .crossDissolve
        menuVC.highlightConfiguration = highlightConfiguration

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
        highlightConfiguration: ViewHighlightConfiguration = .withContextualRotation(),
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        let gestureHandler = LongPressGestureHandler(
            targetView: targetView,
            items: items,
            presentingViewController: presentingViewController,
            highlightConfiguration: highlightConfiguration,
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
        // touchEnded는 메뉴를 dismiss하므로, dismissMenu의 completion에서 resetMenuState 호출됨
    }

    func touchCancelled() {
        currentMenuViewController?.touchCancelled()
        // touchCancelled도 메뉴를 dismiss하므로, dismissMenu의 completion에서 resetMenuState 호출됨
    }

    func resetMenuState() {
        // dismiss completion에서 호출되므로 즉시 리셋
        currentMenuViewController = nil
        isMenuPresented = false
    }
}
