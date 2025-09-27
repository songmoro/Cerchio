//
//  ContextMenu.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import SwiftUI
import SnapKit
import ObjectiveC

// MARK: - Main ContextMenu Class (통합된 매니저 + 컨트롤러)

class ContextMenu {
    static let shared = ContextMenu()
    private init() {}

    private var currentMenuController: ContextMenuController?

    // MARK: - Public API

    /// 간단한 메뉴 표시 (위치 자동 계산)
    static func show(
        from sourceView: UIView,
        items: [ContextMenuItem],
        presentingViewController: UIViewController,
        customization: ((ContextMenuController) -> Void)? = nil
    ) {
        let center = CGPoint(x: sourceView.bounds.midX, y: sourceView.bounds.midY)
        let position = sourceView.convert(center, to: presentingViewController.view)

        show(
            at: position,
            targetView: sourceView,
            items: items,
            from: presentingViewController,
            customization: customization
        )
    }

    /// 정확한 위치 지정 메뉴 표시
    static func show(
        at position: CGPoint,
        targetView: UIView? = nil,
        items: [ContextMenuItem],
        from presentingViewController: UIViewController,
        customization: ((ContextMenuController) -> Void)? = nil
    ) {
        shared.showMenu(
            at: position,
            targetView: targetView,
            items: items,
            from: presentingViewController,
            customization: customization
        )
    }

    /// 롱 프레스 제스처 추가 (자동 좌표 계산)
    static func addLongPress(
        to view: UIView,
        items: [ContextMenuItem],
        presentingViewController: UIViewController,
        minimumPressDuration: TimeInterval = 0.5,
        customization: ((ContextMenuController) -> Void)? = nil
    ) {
        shared.addLongPressGesture(
            to: view,
            items: items,
            presentingViewController: presentingViewController,
            minimumPressDuration: minimumPressDuration,
            customization: customization
        )
    }

    // MARK: - Private Implementation

    private func showMenu(
        at position: CGPoint,
        targetView: UIView?,
        items: [ContextMenuItem],
        from presentingViewController: UIViewController,
        customization: ((ContextMenuController) -> Void)?
    ) {
        let menuController = ContextMenuController(
            position: position,
            targetView: targetView,
            items: items
        )

        customization?(menuController)
        currentMenuController = menuController

        presentingViewController.present(menuController, animated: false) {
            menuController.showMenu()
        }
    }

    private func addLongPressGesture(
        to view: UIView,
        items: [ContextMenuItem],
        presentingViewController: UIViewController,
        minimumPressDuration: TimeInterval,
        customization: ((ContextMenuController) -> Void)?
    ) {
        let handler = ContextMenuGestureHandler(
            sourceView: view,
            items: items,
            presentingViewController: presentingViewController,
            customization: customization
        )

        let longPress = UILongPressGestureRecognizer(
            target: handler,
            action: #selector(ContextMenuGestureHandler.handleLongPress(_:))
        )
        longPress.minimumPressDuration = minimumPressDuration

        view.addGestureRecognizer(longPress)
        view.setContextMenuHandler(handler)
    }

    // MARK: - Touch Handling (Long Press 용)

    func updateTouchLocation(_ location: CGPoint) {
        currentMenuController?.updateTouchLocation(location)
    }

    func touchEnded() {
        currentMenuController?.touchEnded()
        currentMenuController = nil
    }

    func touchCancelled() {
        currentMenuController?.touchCancelled()
        currentMenuController = nil
    }
}

// MARK: - ContextMenuController (통합된 뷰컨트롤러)

class ContextMenuController: UIViewController {
    private let position: CGPoint
    private let targetView: UIView?
    private let items: [ContextMenuItem]

    private var menuView: ContextMenuView!
    private var overlayView: UIView!

    init(position: CGPoint, targetView: UIView?, items: [ContextMenuItem]) {
        self.position = position
        self.targetView = targetView
        self.items = items
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOverlay()
        setupMenuView()
    }

    private func setupOverlay() {
        overlayView = UIView()
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.alpha = 0

        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 배경 탭으로 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        overlayView.addGestureRecognizer(tapGesture)
    }

    private func setupMenuView() {
        menuView = ContextMenuView(
            position: position,
            targetView: targetView,
            items: items
        )

        view.addSubview(menuView)
        menuView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func showMenu() {
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 1
        }
        menuView.showMenu()
    }

    func updateTouchLocation(_ location: CGPoint) {
        menuView.updateTouchLocation(location)
    }

    func touchEnded() {
        menuView.handleTouchEnded { [weak self] in
            self?.dismissMenu()
        }
    }

    func touchCancelled() {
        dismissMenu()
    }

    @objc private func backgroundTapped() {
        dismissMenu()
    }

    private func dismissMenu() {
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 0
            self.menuView.hideMenu()
        }) { _ in
            self.dismiss(animated: false)
        }
    }
}

// MARK: - ContextMenuView (SwiftUI 래퍼)

class ContextMenuView: UIView {
    private let position: CGPoint
    private let targetView: UIView?
    private let items: [ContextMenuItem]

    private var hostingController: UIHostingController<ContextMenuSwiftUIView>!
    private var viewModel: ContextMenuViewModel!

    init(position: CGPoint, targetView: UIView?, items: [ContextMenuItem]) {
        self.position = position
        self.targetView = targetView
        self.items = items
        super.init(frame: .zero)
        setupSwiftUIView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSwiftUIView() {
        viewModel = ContextMenuViewModel(
            position: position,
            targetView: targetView,
            items: items
        )

        let swiftUIView = ContextMenuSwiftUIView(viewModel: viewModel)
        hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear

        addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func showMenu() {
        viewModel.showMenu()
    }

    func hideMenu() {
        viewModel.hideMenu()
    }

    func updateTouchLocation(_ location: CGPoint) {
        viewModel.updateTouchLocation(location)
    }

    func handleTouchEnded(completion: @escaping () -> Void) {
        viewModel.handleTouchEnded(completion: completion)
    }
}

// MARK: - Associated Object Extension

private struct ContextMenuAssociatedKeys {
    static var gestureHandler: UInt8 = 0
}

extension UIView {
    func setContextMenuHandler(_ handler: ContextMenuGestureHandler) {
        objc_setAssociatedObject(self, &ContextMenuAssociatedKeys.gestureHandler, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func getContextMenuHandler() -> ContextMenuGestureHandler? {
        return objc_getAssociatedObject(self, &ContextMenuAssociatedKeys.gestureHandler) as? ContextMenuGestureHandler
    }
}
