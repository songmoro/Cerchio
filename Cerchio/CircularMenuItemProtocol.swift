//
//  CircularMenuItemProtocol.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit
import SnapKit
import Kingfisher

protocol CircularMenuItemProtocol {
    var image: UIImage? { get }
    var backgroundColor: UIColor { get }
    var action: (() -> Void)? { get }
}

struct CircularMenuItem: CircularMenuItemProtocol {
    let image: UIImage?
    let backgroundColor: UIColor
    let action: (() -> Void)?
    
    init(image: UIImage?, backgroundColor: UIColor = .white, action: (() -> Void)? = nil) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.action = action
    }
}

class CircularMenuButton: UIButton {
    var menuItem: CircularMenuItemProtocol?
    private var originalBackgroundColor: UIColor = .white
    private var baseConfiguration: UIButton.Configuration!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 17)
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 0.5)
        layer.shadowRadius = 0.2
        
        self.baseConfiguration = config
        self.configuration = config
    }
    
    func configure(with item: CircularMenuItemProtocol) {
        self.menuItem = item
        originalBackgroundColor = item.backgroundColor
        
        var config = baseConfiguration!
        config.image = item.image
        config.baseBackgroundColor = item.backgroundColor
        config.baseForegroundColor = .black
        
        self.configuration = config
    }
    
    func setHighlighted(_ highlighted: Bool) {
        UIView.animate(withDuration: 0.15) {
            var config = self.baseConfiguration!
            config.image = self.menuItem?.image
            
            if highlighted {
                config.baseBackgroundColor = .black
                config.baseForegroundColor = .white
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            else {
                config.baseBackgroundColor = self.originalBackgroundColor
                config.baseForegroundColor = .black
                self.transform = CGAffineTransform.identity
            }
            
            self.configuration = config
        }
    }
}

class CircularMenuViewController: UIViewController {
    var menuButtons: [CircularMenuButton] = []
    var menuItems: [CircularMenuItemProtocol] = []
    private var originalImageView: UIView!
    private var highlightedButton: CircularMenuButton?
    private var labelView: UIView?
    var centerPoint: CGPoint = .zero
    
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
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func backgroundTapped() {
        dismissMenu()
    }
    
    func showMenu(at point: CGPoint, selectedView: UIView, items: [CircularMenuItemProtocol]) {
        centerPoint = point
        menuItems = items
        originalImageView = selectedView.snapshotView(afterScreenUpdates: true)
        originalImageView.frame = selectedView.frame
        originalImageView.layer.cornerRadius = 8
        originalImageView.layer.masksToBounds = true
        originalImageView.layer.shadowColor = UIColor.black.cgColor
        originalImageView.layer.shadowOpacity = 0.2
        originalImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        originalImageView.layer.shadowRadius = 1
        
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
        }
        else {
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
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
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
            view.addSubview(button)
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
        }
        else {
            let angleStep: CGFloat = 0.6
            
            for i in 0..<buttonCount {
                let angle: CGFloat
                
                if isLeftSide {
                    angle = startAngle + angleStep * CGFloat(i)
                }
                else {
                    angle = startAngle - angleStep * CGFloat(i)
                }
                
                let x = centerPoint.x + menuRadius * cos(angle)
                let y = centerPoint.y + menuRadius * sin(angle)
                print("Button \(i): isLeft=\(isLeftSide), angle=\(angle), x=\(x), y=\(y)")
                
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
        }
        else if point.x > rightBoundary {
            if point.y < topBoundary { return CGFloat.pi / 2 }
            else if point.y > bottomBoundary { return CGFloat.pi }
            else { return 3 * CGFloat.pi / 4 }
        }
        else {
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
        }
        else if adjustedX + buttonRadius > bounds.maxX {
            adjustedX = bounds.maxX - buttonRadius
        }
        
        if adjustedY - buttonRadius < bounds.minY {
            adjustedY = bounds.minY + buttonRadius
        }
        else if adjustedY + buttonRadius > bounds.maxY {
            adjustedY = bounds.maxY - buttonRadius
        }
        
        return CGPoint(x: adjustedX, y: adjustedY)
    }
    
    private func animateIn() {
        UIView.animate(withDuration: animationDuration, delay: 0.3, options: [.curveEaseOut]) {
            self.view.addSubview(self.originalImageView)
            let uiView = UIView(frame: self.originalImageView.frame)
            uiView.backgroundColor = .systemRed.withAlphaComponent(0.3)
            self.view.addSubview(uiView)
            
            for button in self.menuButtons {
                button.alpha = 1
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
            self.dismiss(animated: false)
        }
    }
}

class TapMenuViewController: CircularMenuViewController {
    override func updateTouchLocation(_ location: CGPoint) { }
    override func touchEnded() {
        dismissMenu()
    }
    override func touchCancelled() {
        dismissMenu()
    }
    override func createMenuButtons() {
        menuButtons.forEach { $0.removeFromSuperview() }
        menuButtons.removeAll()
        
        for item in menuItems {
            let button = createTapMenuButton(for: item)
            menuButtons.append(button)
            view.addSubview(button)
        }
    }
    
    private func createTapMenuButton(for item: CircularMenuItemProtocol) -> CircularMenuButton {
        let button = CircularMenuButton(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        button.configure(with: item)
        button.addTarget(self, action: #selector(tapMenuButtonTapped), for: .touchUpInside)
        return button
    }
    
    @objc private func tapMenuButtonTapped(_ sender: CircularMenuButton) {
        sender.menuItem?.action?()
        dismissMenu()
    }
}

protocol CircularMenuDragSelectionDelegate: AnyObject {
    func menuDidAppear()
    func menuDidDisappear()
}

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

extension UIView {
    struct AssociatedKeys {
        /// 실제 값(0)은 중요하지 않음. &longPressHandler의 메모리 주소가 키가 됨
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

//class ViewController: UIViewController {
//    private let longPressButton = UIButton(type: .system)
//    private let tapButton = UIButton(type: .system)
//    private let imageView = UIImageView()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupCircularMenus()
//    }
//    
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        
//        longPressButton.setTitle("Long Press Menu", for: .normal)
//        longPressButton.backgroundColor = .systemBlue
//        longPressButton.setTitleColor(.white, for: .normal)
//        longPressButton.layer.cornerRadius = 8
//        longPressButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        tapButton.setTitle("Tap Menu", for: .normal)
//        tapButton.backgroundColor = .systemGreen
//        tapButton.setTitleColor(.white, for: .normal)
//        tapButton.layer.cornerRadius = 8
//        tapButton.translatesAutoresizingMaskIntoConstraints = false
//        
//        view.addSubview(longPressButton)
//        view.addSubview(tapButton)
//        view.addSubview(imageView)
//        
//        longPressButton.snp.makeConstraints {
//            $0.centerX.equalToSuperview()
//            $0.centerY.equalToSuperview().offset(-50)
//            $0.width.equalTo(150)
//            $0.height.equalTo(44)
//        }
//        
//        tapButton.snp.makeConstraints {
//            $0.centerX.equalToSuperview()
//            $0.centerY.equalToSuperview().offset(50)
//            $0.width.equalTo(150)
//            $0.height.equalTo(44)
//        }
//        
//        imageView.snp.makeConstraints {
//            $0.top.horizontalEdges.equalToSuperview(\.safeAreaLayoutGuide).inset(30)
//            $0.height.equalTo(200)
//        }
//        
//        imageView.backgroundColor = .systemGray5
//        imageView.contentMode = .scaleAspectFit
//    }
//    
//    private func setupCircularMenus() {
//        let menuItems: [CircularMenuItem] = [
//            CircularMenuItem(image: UIImage(systemName: "camera")) {
//                print("카메라 선택됨")
//            },
//            CircularMenuItem(image: UIImage(systemName: "photo")) {
//                print("갤러리 선택됨")
//            },
//            CircularMenuItem(image: UIImage(systemName: "video")) {
//                print("비디오 선택됨")
//            },
//            CircularMenuItem(image: UIImage(systemName: "doc")) {
//                print("문서 선택됨")
//            },
//            CircularMenuItem(image: UIImage(systemName: "star")) {
//                print("즐겨찾기 선택됨")
//            }
//        ]
//        
//        CircularMenuManager.shared.addLongPressMenu(
//            to: longPressButton,
//            targetView: imageView,
//            items: menuItems,
//            presentingViewController: self,
//            minimumPressDuration: 0.5
//        )
//        
//        CircularMenuManager.shared.addTapMenu(
//            to: tapButton,
//            targetView: imageView,
//            items: menuItems,
//            presentingViewController: self
//        )
//    }
//}
