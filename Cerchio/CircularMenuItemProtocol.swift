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
    private var menuButtons: [CircularMenuButton] = []
    private var menuItems: [CircularMenuItemProtocol] = []
    private var originalImageView: UIView!
    private var highlightedButton: CircularMenuButton?
    private var labelView: UIView?
    private var centerPoint: CGPoint = .zero
    
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
            let buttonFrame = button.frame
            let distance = sqrt(pow(location.x - button.center.x, 2) + pow(location.y - button.center.y, 2))
            if distance <= buttonSize / 2 {
                return button
            }
        }
        return nil
    }
    
    private func createMenuButtons() {
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
        // 기존 탭 제스처는 제거 (드래그로 대체)
        return button
    }
    
    private func positionButtons(centerPoint: CGPoint) {
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
            let angleStep = 0.6 // 버튼 간격 (라디안)
            
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
    
    private func dismissMenu() {
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

// 드래그 선택을 위한 델리게이트 프로토콜
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
    
    // 터치 위치 업데이트
    func updateTouchLocation(_ location: CGPoint) {
        currentMenuViewController?.updateTouchLocation(location)
    }
    
    // 터치 종료
    func touchEnded() {
        currentMenuViewController?.touchEnded()
        currentMenuViewController = nil
    }
    
    // 터치 취소
    func touchCancelled() {
        currentMenuViewController?.touchCancelled()
        currentMenuViewController = nil
    }
}

class ViewController: UIViewController {
    private let targetButton = UIButton(type: .system)
    private let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        targetButton.setTitle("Long Press Me", for: .normal)
        targetButton.backgroundColor = .systemBlue
        targetButton.setTitleColor(.white, for: .normal)
        targetButton.layer.cornerRadius = 8
        targetButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(targetButton)
        view.addSubview(imageView)
        
        targetButton.snp.makeConstraints {
//            $0.center.equalToSuperview()
//            $0.size.equalTo(40)
            $0.edges.equalToSuperview()
        }
        
        imageView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview(\.safeAreaLayoutGuide).inset(30)
            $0.height.equalTo(200)
        }
        
        if let url = URL(string: Book.sample[0].image) {
            imageView.kf.setImage(with: url)
        }
    }
    
    private func setupGestures() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPress.minimumPressDuration = 0.5
        targetButton.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let point = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            // 롱프레스 시작 - 메뉴 표시
            showCircularMenu(at: point, selectedView: imageView)
            
        case .changed:
            // 롱프레스 중 손가락 이동 - 터치 위치 업데이트
            CircularMenuManager.shared.updateTouchLocation(point)
            
        case .ended:
            // 롱프레스 종료 - 선택된 버튼 실행
            CircularMenuManager.shared.touchEnded()
            
        case .cancelled, .failed:
            // 롱프레스 취소 - 메뉴 닫기
            CircularMenuManager.shared.touchCancelled()
            
        default:
            break
        }
    }
    
    private func showCircularMenu(at point: CGPoint, selectedView: UIView, completion: (() -> Void)? = nil) {
        let items: [CircularMenuItem] = [
            CircularMenuItem(image: UIImage(systemName: "camera")) {
                print("카메라 선택됨")
                completion?()
            },
            CircularMenuItem(image: UIImage(systemName: "photo")) {
                print("갤러리 선택됨")
                completion?()
            },
            CircularMenuItem(image: UIImage(systemName: "video")) {
                print("비디오 선택됨")
                completion?()
            },
            CircularMenuItem(image: UIImage(systemName: "doc")) {
                print("문서 선택됨")
                completion?()
            },
            CircularMenuItem(image: UIImage(systemName: "star")) {
                print("즐겨찾기 선택됨")
                completion?()
            }
        ]
        
        CircularMenuManager.shared.showMenu(
            at: point,
            selectedView: selectedView,
            items: items,
            from: self
        )
    }
}
