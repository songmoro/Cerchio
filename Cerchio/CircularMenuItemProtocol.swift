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
        // Configuration 기반 설정
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24)
        
        // 그림자 효과를 위한 레이어 설정은 유지
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
        
        // Configuration 업데이트
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
                // 검은 배경에 흰색 이미지로 색상 반전 효과
                config.baseBackgroundColor = .black
                config.baseForegroundColor = .white
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            } else {
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
    
    // 드래그 선택을 위한 델리게이트
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
    
    // 외부에서 터치 위치를 업데이트할 수 있는 메서드
    func updateTouchLocation(_ location: CGPoint) {
        let newHighlightedButton = findButtonAtLocation(location)
        
        if newHighlightedButton != highlightedButton {
            highlightedButton?.setHighlighted(false)
            highlightedButton = newHighlightedButton
            highlightedButton?.setHighlighted(true)
            
            // 레이블 업데이트
            updateLabel(for: highlightedButton)
        }
    }
    
    private func updateLabel(for button: CircularMenuButton?) {
        // 기존 레이블 제거
        labelView?.removeFromSuperview()
        labelView = nil
        
        guard let button = button else { return }
        
        // 버튼의 레이블 텍스트 (예시로 SF Symbol 이름 사용)
        let labelText = getLabelText(for: button)
        
        // 레이블 위치 계산
        let labelPosition = calculateLabelPosition(for: button)
        
        // 레이블 생성
        labelView = createLabel(text: labelText, at: labelPosition)
        if let labelView = labelView {
            view.addSubview(labelView)
            
            // 애니메이션으로 나타나기
            labelView.alpha = 0
            labelView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.2) {
                labelView.alpha = 1
                labelView.transform = CGAffineTransform.identity
            }
        }
    }
    
    private func getLabelText(for button: CircularMenuButton) -> String {
        // 각 버튼에 맞는 레이블 텍스트 반환 (예시)
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
        
        // 버튼이 화면 중앙 기준 왼쪽/오른쪽 어디에 있는지 확인
        let isButtonOnLeft = button.center.x < screenCenter.x
        
        // 반대편에 레이블 배치 (일단 중앙만)
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
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        
        // 레이블 크기 계산
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
    
    // 터치가 종료되었을 때 호출되는 메서드
    func touchEnded() {
        if let button = highlightedButton {
            button.menuItem?.action?()
        }
        dismissMenu()
    }
    
    // 터치가 취소되었을 때 호출되는 메서드
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
        // Long press 버전에서는 탭 제스처 추가하지 않음 (드래그로 대체)
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
            let angleStep: CGFloat = 0.6 // 버튼 간격 (라디안)
            
            for i in 0..<buttonCount {
                let angle: CGFloat
                
                if isLeftSide {
                    // 왼쪽: 시계방향
                    angle = startAngle + angleStep * CGFloat(i)
                } else {
                    // 오른쪽: 반시계방향
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
        
        let leftBoundary = centerX * 0.3   // 왼쪽 30% 지점
        let rightBoundary = centerX * 1.7  // 오른쪽 70% 지점
        let topBoundary = centerY * 0.3    // 위쪽 30% 지점
        let bottomBoundary = centerY * 1.7 // 아래쪽 70% 지점
        
        // 9개 영역으로 구분
        if point.x < leftBoundary {
            // 왼쪽 영역
            if point.y < topBoundary {
                return 0 // 왼쪽 위
            } else if point.y > bottomBoundary {
                return -CGFloat.pi / 2 // 왼쪽 아래
            } else {
                return -CGFloat.pi / 4 // 왼쪽 중앙
            }
        } else if point.x > rightBoundary {
            // 오른쪽 영역
            if point.y < topBoundary {
                return CGFloat.pi / 2 // 오른쪽 위
            } else if point.y > bottomBoundary {
                return CGFloat.pi // 오른쪽 아래
            } else {
                return 3 * CGFloat.pi / 4 // 오른쪽 중앙
            }
        } else {
            // 중앙 영역 (가로 중앙)
            if point.y < centerY {
                return CGFloat.pi / 4 // 위쪽 중앙
            } else {
                return -3 * CGFloat.pi / 4 // 아래쪽 중앙
            }
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
        
        // 레이블도 함께 제거
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

// MARK: - Tap Menu ViewController (탭 전용)
class TapMenuViewController: CircularMenuViewController {
    override func updateTouchLocation(_ location: CGPoint) {
        // 탭 버전에서는 드래그 기능 비활성화
    }
    
    override func touchEnded() {
        // 탭 버전에서는 터치 엔드 시 자동으로 닫기만
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

// 드래그 선택을 위한 델리게이트 프로토콜
protocol CircularMenuDragSelectionDelegate: AnyObject {
    func menuDidAppear()
    func menuDidDisappear()
}

class CircularMenuManager {
    static let shared = CircularMenuManager()
    private init() {}
    private var currentMenuViewController: CircularMenuViewController?
    
    // MARK: - Manual API (기존 기능)
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
    
    // MARK: - Long Press Gesture API
    func addLongPressMenu(
        to view: UIView,
        targetView: UIView,
        items: [CircularMenuItemProtocol],
        presentingViewController: UIViewController,
        minimumPressDuration: TimeInterval = 0.5,
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        // Handler 객체 생성
        let gestureHandler = LongPressGestureHandler(
            targetView: targetView,
            items: items,
            presentingViewController: presentingViewController,
            customization: customization
        )
        
        // 제스처 생성 및 연결
        let longPress = UILongPressGestureRecognizer(target: gestureHandler, action: #selector(LongPressGestureHandler.handleGesture(_:)))
        longPress.minimumPressDuration = minimumPressDuration
        
        view.addGestureRecognizer(longPress)
        
        // 중요: 뷰에 핸들러를 연결하여 뷰가 살아있는 동안 핸들러도 유지
        view.setAssociatedLongPressHandler(gestureHandler)
    }
    
    // MARK: - Tap Gesture API
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
        
        // 뷰에 핸들러 연결
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
        /*
         ⚠️ 순환 참조 주의사항:
         - UIView → LongPressGestureHandler (강한 참조, Associated Object)
         - LongPressGestureHandler → UIViewController (약한 참조, weak)
         
         만약 handler가 view를 강하게 참조한다면:
         UIView ↔ LongPressGestureHandler 순환 참조 발생!
         
         현재 코드는 handler에서 targetView를 강한 참조하지만
         targetView ≠ 이 view(제스처가 달린 view) 이므로 안전함
         */
        objc_setAssociatedObject(
            self,  // 이 UIView 인스턴스의 연관 객체 저장소에
            &AssociatedKeys.longPressHandler,  // 이 키로
            handler,  // 이 객체를 저장
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC  // 강한 참조, non-atomic
        )
        
        /*
         Policy 선택 이유:
         - RETAIN: handler 객체를 강하게 참조해야 GestureRecognizer가 작동
         - NONATOMIC: UI는 메인 스레드에서만 접근하므로 atomic 불필요
         
         만약 멀티스레드 접근이 필요하다면:
         .OBJC_ASSOCIATION_RETAIN 사용 (atomic, 더 느림)
         */
    }
    
    func getAssociatedLongPressHandler() -> LongPressGestureHandler? {
        /*
         타입 캐스팅 주의사항:
         - objc_getAssociatedObject는 Any?를 반환
         - 잘못된 타입으로 캐스팅하면 nil 반환 (크래시 X)
         - 하지만 런타임에만 확인 가능하므로 실수 위험
         */
        return objc_getAssociatedObject(self, &AssociatedKeys.longPressHandler) as? LongPressGestureHandler
    }
    
    func setAssociatedTapHandler(_ handler: TapGestureHandler) {
        // 다른 키 사용으로 longPressHandler와 충돌 방지
        objc_setAssociatedObject(
            self,
            &AssociatedKeys.tapHandler,  // 다른 메모리 주소
            handler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
    
    func getAssociatedTapHandler() -> TapGestureHandler? {
        return objc_getAssociatedObject(self, &AssociatedKeys.tapHandler) as? TapGestureHandler
    }
    
    /*
     추가 주의사항들:
     
     1. 메모리 누수 디버깅:
        - Xcode Memory Graph로 Associated Objects 추적 가능
        - Instruments의 Leaks 도구로 순환 참조 확인
     
     2. 성능 고려사항:
        - objc_getAssociatedObject는 O(1)이지만 해시 계산 오버헤드
        - 자주 접근하는 값이라면 캐싱 고려
     
     3. KVO/KVC와의 상호작용:
        - Associated Property는 KVO 알림 자동 발생 안 함
        - 필요시 수동으로 willSet/didSet 호출해야 함
     
     4. Swizzling과의 충돌:
        - Method Swizzling 사용 시 Associated Objects에 영향 줄 수 있음
        - 특히 dealloc 스위즐링 시 주의 필요
     */
}

// MARK: - Gesture Handlers
class LongPressGestureHandler: NSObject {
    private let targetView: UIView
    private let items: [CircularMenuItemProtocol]
    
    /*
     중요: weak 참조 사용
     - 뷰 → 핸들러 (강한 참조, Associated Object)
     - 핸들러 → 뷰컨트롤러 (약한 참조)
     이렇게 하면 순환 참조 방지
     */
    private weak var presentingViewController: UIViewController?
    private let customization: ((CircularMenuViewController) -> Void)?
    
    init(
        targetView: UIView,
        items: [CircularMenuItemProtocol],
        presentingViewController: UIViewController,
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
        self.targetView = targetView
        self.items = items
        self.presentingViewController = presentingViewController // weak 참조로 순환 참조 방지
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
    private weak var presentingViewController: UIViewController? // 순환 참조 방지
    private let customization: ((CircularMenuViewController) -> Void)?
    
    init(
        targetView: UIView,
        items: [CircularMenuItemProtocol],
        presentingViewController: UIViewController,
        customization: ((CircularMenuViewController) -> Void)? = nil
    ) {
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

class ViewController: UIViewController {
    private let longPressButton = UIButton(type: .system)
    private let tapButton = UIButton(type: .system)
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCircularMenus()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Long Press 버튼
        longPressButton.setTitle("Long Press Menu", for: .normal)
        longPressButton.backgroundColor = .systemBlue
        longPressButton.setTitleColor(.white, for: .normal)
        longPressButton.layer.cornerRadius = 8
        longPressButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Tap 버튼
        tapButton.setTitle("Tap Menu", for: .normal)
        tapButton.backgroundColor = .systemGreen
        tapButton.setTitleColor(.white, for: .normal)
        tapButton.layer.cornerRadius = 8
        tapButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(longPressButton)
        view.addSubview(tapButton)
        view.addSubview(imageView)
        
        longPressButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-50)
            $0.width.equalTo(150)
            $0.height.equalTo(44)
        }
        
        tapButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(50)
            $0.width.equalTo(150)
            $0.height.equalTo(44)
        }
        
        imageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview(\.safeAreaLayoutGuide).inset(30)
            $0.height.equalTo(200)
        }
        
        // Book.sample 참조 제거 - 테스트용 이미지로 대체
        imageView.backgroundColor = .systemGray5
        imageView.contentMode = .scaleAspectFit
    }
    
    private func setupCircularMenus() {
        let menuItems: [CircularMenuItem] = [
            CircularMenuItem(image: UIImage(systemName: "camera")) {
                print("카메라 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "photo")) {
                print("갤러리 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "video")) {
                print("비디오 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "doc")) {
                print("문서 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "star")) {
                print("즐겨찾기 선택됨")
            }
        ]
        
        // Long Press 버전 - 드래그로 선택 가능
        CircularMenuManager.shared.addLongPressMenu(
            to: longPressButton,
            targetView: imageView,
            items: menuItems,
            presentingViewController: self,
            minimumPressDuration: 0.5
        )
        
        // Tap 버전 - 일반적인 버튼 탭으로 선택
        CircularMenuManager.shared.addTapMenu(
            to: tapButton,
            targetView: imageView,
            items: menuItems,
            presentingViewController: self
        )
    }
}
