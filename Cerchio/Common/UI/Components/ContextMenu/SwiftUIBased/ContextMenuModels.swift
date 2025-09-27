////
////  CircularMenuModels.swift
////  Cerchio
////
////  Created by 송재훈 on 9/26/25.
////
//
//import UIKit
//import SwiftUI
//import Combine
//import ObjectiveC
//
//// MARK: - ContextMenuItem
//
//struct ContextMenuItem: Identifiable {
//    let id = UUID()
//    let image: UIImage?
//    let backgroundColor: UIColor
//    let action: (() -> Void)?
//
//    init(image: UIImage?, backgroundColor: UIColor = .white, action: (() -> Void)? = nil) {
//        self.image = image
//        self.backgroundColor = backgroundColor
//        self.action = action
//    }
//
//    // 편의 생성자
//    static func create(
//        systemName: String,
//        backgroundColor: UIColor = .systemBlue,
//        action: (() -> Void)? = nil
//    ) -> ContextMenuItem {
//        return ContextMenuItem(
//            image: UIImage(systemName: systemName),
//            backgroundColor: backgroundColor,
//            action: action
//        )
//    }
//}
//
//// MARK: - ContextMenuGestureHandler
//
//class ContextMenuGestureHandler: NSObject {
//    private weak var sourceView: UIView?
//    private let items: [ContextMenuItem]
//    private weak var presentingViewController: UIViewController?
//    private let customization: ((ContextMenuController) -> Void)?
//
//    init(
//        sourceView: UIView,
//        items: [ContextMenuItem],
//        presentingViewController: UIViewController,
//        customization: ((ContextMenuController) -> Void)? = nil
//    ) {
//        self.sourceView = sourceView
//        self.items = items
//        self.presentingViewController = presentingViewController
//        self.customization = customization
//        super.init()
//    }
//
//    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
//        guard let sourceView = sourceView,
//              let presentingVC = presentingViewController else { return }
//
//        switch gesture.state {
//        case .began:
//            // 실제 터치한 위치를 사용 (셀 중앙이 아닌)
//            let touchLocationInSource = gesture.location(in: sourceView)
//            let touchLocationInPresentingView = sourceView.convert(touchLocationInSource, to: presentingVC.view)
//
//            // Safe area top offset 계산 (네비게이션 바 영향 제거)
//            let safeAreaTop = presentingVC.view.safeAreaInsets.top
//            let adjustedPosition = CGPoint(
//                x: touchLocationInPresentingView.x,
//                y: touchLocationInPresentingView.y
//            )
//
//            ContextMenu.show(
//                at: adjustedPosition,
//                targetView: sourceView,
//                items: items,
//                from: presentingVC,
//                customization: customization
//            )
//
//        case .changed:
//            let location = gesture.location(in: presentingVC.view)
//            ContextMenu.shared.updateTouchLocation(location)
//
//        case .ended:
//            ContextMenu.shared.touchEnded()
//
//        case .cancelled, .failed:
//            ContextMenu.shared.touchCancelled()
//
//        default:
//            break
//        }
//    }
//}
//
//// MARK: - ContextMenuViewModel
//
//class ContextMenuViewModel: ObservableObject {
//    @Published var isVisible: Bool = false
//    @Published var selectedIndex: Int? = nil
//
//    let position: CGPoint
//    let targetView: UIView?
//    let items: [ContextMenuItem]
//
//    private var touchLocation: CGPoint = .zero
//    private let menuRadius: CGFloat = 80
//    private let buttonRadius: CGFloat = 25
//
//    init(position: CGPoint, targetView: UIView?, items: [ContextMenuItem]) {
//        self.position = position
//        self.targetView = targetView
//        self.items = items
//    }
//
//    func showMenu() {
//        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
//            isVisible = true
//        }
//    }
//
//    func hideMenu() {
//        withAnimation(.easeInOut(duration: 0.3)) {
//            isVisible = false
//        }
//    }
//
//    func updateTouchLocation(_ location: CGPoint) {
//        touchLocation = location
//
//        // 터치 위치에 따른 선택된 아이템 계산
//        let distance = sqrt(pow(location.x - position.x, 2) + pow(location.y - position.y, 2))
//
//        if distance > menuRadius - buttonRadius && distance < menuRadius + buttonRadius {
//            let angle = atan2(location.y - position.y, location.x - position.x)
//            let adjustedAngle = angle < 0 ? angle + 2 * .pi : angle
//            let itemAngle = 2 * .pi / CGFloat(items.count)
//            let index = Int((adjustedAngle + itemAngle/2) / itemAngle) % items.count
//
//            selectedIndex = index
//        } else {
//            selectedIndex = nil
//        }
//    }
//
//    func handleTouchEnded(completion: @escaping () -> Void) {
//        if let selectedIndex = selectedIndex {
//            // 선택된 아이템의 액션 실행
//            items[selectedIndex].action?()
//        }
//        completion()
//    }
//
//    // 각 버튼의 위치 계산
//    func buttonPosition(for index: Int) -> CGPoint {
//        let angle = 2 * .pi * CGFloat(index) / CGFloat(items.count) - .pi/2 // -90도부터 시작
//        let x = position.x + menuRadius * cos(angle)
//        let y = position.y + menuRadius * sin(angle)
//        return CGPoint(x: x, y: y)
//    }
//
//    func isButtonSelected(_ index: Int) -> Bool {
//        return selectedIndex == index
//    }
//}
