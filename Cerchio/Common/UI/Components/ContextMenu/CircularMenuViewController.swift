//
//  CircularMenuViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit
import SnapKit

class CircularMenuViewController: UIViewController {
    var menuButtons: [CircularMenuButton] = []
    var menuItems: [CircularMenuItemProtocol] = []
    private var originalImageView: UIView!
    private var highlightedButton: CircularMenuButton?
    private var labelView: UIView?
    var centerPoint: CGPoint = .zero

    // 원본 뷰 참조 저장 (숨기기/보이기 관리용)
    private weak var originalView: UIView?

    var buttonSize: CGFloat = 50
    var menuRadius: CGFloat = 100
    var animationDuration: TimeInterval = 0.3
    var arcAngle: CGFloat = CGFloat.pi

    weak var dragSelectionDelegate: CircularMenuDragSelectionDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        view.backgroundColor = UIColor.white.withAlphaComponent(0.9)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func backgroundTapped() {
        dismissMenu()
    }

    func showMenu(at point: CGPoint, selectedView: UIView, items: [CircularMenuItemProtocol]) {
        centerPoint = point
        menuItems = items
        originalView = selectedView // 원본 뷰 참조 저장
        originalImageView = selectedView.snapshotView(afterScreenUpdates: true)

        // 정확한 좌표 계산: selectedView의 프레임을 현재 뷰 컨트롤러의 뷰 좌표계로 변환
        guard let superview = selectedView.superview else { return }
        let frameInCurrentView = superview.convert(selectedView.frame, to: self.view)

        // 1.2배 크기로 확대하고 중앙 정렬
        let scaledWidth = frameInCurrentView.width * 1.0
        let scaledHeight = frameInCurrentView.height * 1.0
        let scaledFrame = CGRect(
            x: frameInCurrentView.midX - scaledWidth / 2,
            y: frameInCurrentView.midY - scaledHeight / 2,
            width: scaledWidth,
            height: scaledHeight
        )

        originalImageView.frame = scaledFrame
        originalImageView.layer.cornerRadius = 8 * 1.0 // 코너 반지름도 비례적으로 증가
        originalImageView.layer.masksToBounds = true
        originalImageView.layer.shadowColor = UIColor.black.cgColor
        originalImageView.layer.shadowOpacity = 0.2
        originalImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        originalImageView.layer.shadowRadius = 1

        let screenCenter = view.bounds.midX
        let tiltAngle: CGFloat = frameInCurrentView.midX < screenCenter ? -5 : 5
        let radians = tiltAngle * .pi / 180 // 라디안으로 변환
        originalImageView.transform = CGAffineTransform(rotationAngle: radians)

        // 원본 뷰 숨기기
        selectedView.alpha = 0

        createMenuButtons()
        positionButtons(centerPoint: point)
        animateIn()
    }

    func updateTouchLocation(_ location: CGPoint) {
        let newHighlightedButton = findButtonAtLocation(location)

        if newHighlightedButton != highlightedButton {
            highlightedButton?.setHighlighted(false)
            highlightedButton = newHighlightedButton
            highlightedButton?.setHighlighted(true)

            updateLabel(for: highlightedButton)
        }
    }

    private func updateLabel(for button: CircularMenuButton?) {
        labelView?.removeFromSuperview()
        labelView = nil

        guard let button = button else { return }

        let labelText = getLabelText(for: button)
        let labelPosition = calculateLabelPosition(for: button)
        labelView = createLabel(text: labelText, at: labelPosition)

        if let labelView = labelView {
            view.addSubview(labelView)

            labelView.alpha = 0
            labelView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.2) {
                labelView.alpha = 1
                labelView.transform = CGAffineTransform.identity
            }
        }
    }

    private func getLabelText(for button: CircularMenuButton) -> String {
        guard let image = button.menuItem?.image else { return "" }

        if image.isEqual(UIImage(systemName: "camera")) {
            return "카메라"
        } else if image.isEqual(UIImage(systemName: "photo")) {
            return "갤러리"
        } else if image.isEqual(UIImage(systemName: "video")) {
            return "비디오"
        } else if image.isEqual(UIImage(systemName: "doc")) {
            return "문서"
        } else if image.isEqual(UIImage(systemName: "star")) {
            return "즐겨찾기"
        }

        return "메뉴"
    }

    private func calculateLabelPosition(for button: CircularMenuButton) -> LabelPosition {
        let screenBounds = view.bounds
        let screenCenter = CGPoint(x: screenBounds.midX, y: screenBounds.midY)

        let isButtonOnLeft = button.center.x < screenCenter.x

        if isButtonOnLeft {
            return .rightCenter
        } else {
            return .leftCenter
        }
    }

    private enum LabelPosition {
        case leftTop, rightTop
        case leftCenter, rightCenter
        case leftBottom, rightBottom
    }

    private func createLabel(text: String, at position: LabelPosition) -> UIView {
        let label = UILabel()
        label.text = text
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center

        label.sizeToFit()
        let labelSize = label.bounds.size
        let screenBounds = view.bounds
        let margin: CGFloat = 40

        var labelFrame: CGRect

        switch position {
        case .leftTop:
            labelFrame = CGRect(
                x: margin,
                y: margin + view.safeAreaInsets.top,
                width: labelSize.width,
                height: labelSize.height
            )
        case .rightTop:
            labelFrame = CGRect(
                x: screenBounds.width - labelSize.width - margin,
                y: margin + view.safeAreaInsets.top,
                width: labelSize.width,
                height: labelSize.height
            )
        case .leftCenter:
            labelFrame = CGRect(
                x: margin,
                y: screenBounds.midY - labelSize.height / 2,
                width: labelSize.width,
                height: labelSize.height
            )
        case .rightCenter:
            labelFrame = CGRect(
                x: screenBounds.width - labelSize.width - margin,
                y: screenBounds.midY - labelSize.height / 2,
                width: labelSize.width,
                height: labelSize.height
            )
        case .leftBottom:
            labelFrame = CGRect(
                x: margin,
                y: screenBounds.height - labelSize.height - margin - view.safeAreaInsets.bottom,
                width: labelSize.width,
                height: labelSize.height
            )
        case .rightBottom:
            labelFrame = CGRect(
                x: screenBounds.width - labelSize.width - margin,
                y: screenBounds.height - labelSize.height - margin - view.safeAreaInsets.bottom,
                width: labelSize.width,
                height: labelSize.height
            )
        }

        label.frame = labelFrame
        return label
    }

    func touchEnded() {
        if let button = highlightedButton {
            button.menuItem?.action?()
        }
        dismissMenu()
    }

    func touchCancelled() {
        dismissMenu()
    }

    private func findButtonAtLocation(_ location: CGPoint) -> CircularMenuButton? {
        for button in menuButtons {
            let distance = sqrt(pow(location.x - button.center.x, 2) + pow(location.y - button.center.y, 2))
            if distance <= buttonSize / 2 {
                return button
            }
        }
        return nil
    }

    func createMenuButtons() {
        menuButtons.forEach { $0.removeFromSuperview() }
        menuButtons.removeAll()

        for item in menuItems {
            let button = createMenuButton(for: item)
            menuButtons.append(button)
        }
    }

    private func createMenuButton(for item: CircularMenuItemProtocol) -> CircularMenuButton {
        let button = CircularMenuButton(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        button.configure(with: item)
        return button
    }

    func positionButtons(centerPoint: CGPoint) {
        let buttonCount = menuButtons.count
        guard buttonCount > 0 else { return }

        let positions = calculateArcPositions(centerPoint: centerPoint, buttonCount: buttonCount)

        for (index, button) in menuButtons.enumerated() {
            if index < positions.count {
                button.center = positions[index]
                button.alpha = 0
                button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }
    }

    private func calculateArcPositions(centerPoint: CGPoint, buttonCount: Int) -> [CGPoint] {
        guard buttonCount > 0 else { return [] }

        let screenBounds = view.bounds
        let startAngle = determineStartAngle(for: centerPoint, in: screenBounds)
        let isLeftSide = centerPoint.x < screenBounds.width / 2

        var positions: [CGPoint] = []

        if buttonCount == 1 {
            let angle = startAngle
            let x = centerPoint.x + menuRadius * cos(angle)
            let y = centerPoint.y + menuRadius * sin(angle)
            positions.append(adjustPositionForScreenBounds(CGPoint(x: x, y: y)))
        } else {
            let angleStep: CGFloat = 0.6

            for i in 0..<buttonCount {
                let angle: CGFloat

                if isLeftSide {
                    angle = startAngle + angleStep * CGFloat(i)
                } else {
                    angle = startAngle - angleStep * CGFloat(i)
                }

                let x = centerPoint.x + menuRadius * cos(angle)
                let y = centerPoint.y + menuRadius * sin(angle)
//                print("Button \(i): isLeft=\(isLeftSide), angle=\(angle), x=\(x), y=\(y)")

                positions.append(adjustPositionForScreenBounds(CGPoint(x: x, y: y)))
            }
        }

        return positions
    }

    private func determineStartAngle(for point: CGPoint, in bounds: CGRect) -> CGFloat {
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2

        let leftBoundary = centerX * 0.3
        let rightBoundary = centerX * 1.7
        let topBoundary = centerY * 0.3
        let bottomBoundary = centerY * 1.7

        if point.x < leftBoundary {
            if point.y < topBoundary { return 0 }
            else if point.y > bottomBoundary { return -CGFloat.pi }
            else { return -CGFloat.pi / 4 }
        } else if point.x > rightBoundary {
            if point.y < topBoundary { return CGFloat.pi / 2 }
            else if point.y > bottomBoundary { return CGFloat.pi }
            else { return 3 * CGFloat.pi / 4 }
        } else {
            if point.y < centerY { return CGFloat.pi / 4 }
            else { return -3 * CGFloat.pi / 4 }
        }
    }

    private func adjustPositionForScreenBounds(_ position: CGPoint) -> CGPoint {
        let bounds = view.bounds
        let buttonRadius = buttonSize / 2

        var adjustedX = position.x
        var adjustedY = position.y

        if adjustedX - buttonRadius < bounds.minX {
            adjustedX = bounds.minX + buttonRadius
        } else if adjustedX + buttonRadius > bounds.maxX {
            adjustedX = bounds.maxX - buttonRadius
        }

        if adjustedY - buttonRadius < bounds.minY {
            adjustedY = bounds.minY + buttonRadius
        } else if adjustedY + buttonRadius > bounds.maxY {
            adjustedY = bounds.maxY - buttonRadius
        }

        return CGPoint(x: adjustedX, y: adjustedY)
    }

    private func animateIn() {
        UIView.animate(withDuration: animationDuration, delay: 0.3, options: [.curveEaseOut]) {
            self.view.addSubview(self.originalImageView)
//            let uiView = UIView(frame: self.originalImageView.frame)
//            uiView.backgroundColor = .systemRed.withAlphaComponent(0.3)
//            self.view.addSubview(uiView)

            for button in self.menuButtons {
                button.alpha = 1
                self.view.addSubview(button)
                button.transform = CGAffineTransform.identity
            }
        }
    }

    func dismissMenu() {
        highlightedButton?.setHighlighted(false)
        highlightedButton = nil

        labelView?.removeFromSuperview()
        labelView = nil

        UIView.animate(withDuration: animationDuration, animations: {
            for button in self.menuButtons {
                button.alpha = 0
                button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            }
        }) { _ in
            // 메뉴가 사라지기 전에 원본 뷰 다시 보이기
            self.originalView?.alpha = 1
            self.dismiss(animated: false)
        }
    }
}
