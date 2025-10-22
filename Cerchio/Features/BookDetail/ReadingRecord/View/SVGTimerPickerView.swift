//
//  SVGTimerPickerView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import SnapKit

final class SVGTimerPickerView: UIView {

    // MARK: - UI Components
    private let imageMaskLayer = CALayer()
    private let gaugeLayer = CAShapeLayer()
    private let tickMarksLayer = CAShapeLayer()
    private let handleView = UIView()
    private var timeLabels: [UILabel] = []

    // MARK: - Properties
    var selectedMinutes: Int = 25 {
        didSet {
            updateUI()
            onTimeChanged?(selectedMinutes)
        }
    }

    var onTimeChanged: ((Int) -> Void)?

    private let minMinutes = 1
    private let maxMinutes = 60
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Constants
    private let gaugeColor: UIColor
    private let tickColor: UIColor
    private let radius: CGFloat
    private let handleSize: CGFloat = 20

    private var boundaryPath: UIBezierPath?
    private var normalizedBoundaryPath: UIBezierPath?

    // MARK: - Initialization
    init(
        maskImage: UIImage? = nil,
        maskImageName: String? = nil,
        svgFileName: String? = nil,
        gaugeColor: UIColor = .forestGreen,
        radius: CGFloat = 120,
        frame: CGRect = .zero
    ) {
        self.gaugeColor = gaugeColor
        self.tickColor = gaugeColor.withAlphaComponent(0.3)
        self.radius = radius

        super.init(frame: frame)

        // SVG 파일에서 경계 경로 로드
        if let svgFile = svgFileName {
            self.boundaryPath = UIBezierPath(svgFileName: svgFile)
        }

        setupUI(maskImage: maskImage, maskImageName: maskImageName)
        setupGesture()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI(maskImage: UIImage?, maskImageName: String?) {
        backgroundColor = .clear

        tickMarksLayer.fillColor = UIColor.clear.cgColor
        tickMarksLayer.strokeColor = tickColor.cgColor
        layer.addSublayer(tickMarksLayer)

        if let image = maskImage ?? (maskImageName.flatMap { UIImage(named: $0) }) {
            imageMaskLayer.contents = image.cgImage
            imageMaskLayer.contentsGravity = .resizeAspect
        }

        gaugeLayer.fillColor = gaugeColor.cgColor
        gaugeLayer.strokeColor = UIColor.clear.cgColor
        gaugeLayer.mask = imageMaskLayer
        layer.addSublayer(gaugeLayer)

        handleView.backgroundColor = .systemBackground
        handleView.layer.cornerRadius = handleSize / 2
        handleView.layer.borderWidth = 3
        handleView.layer.borderColor = gaugeColor.cgColor
        addSubview(handleView)

        createTimeLabels()
    }

    private func createTimeLabels() {
        for minute in stride(from: 5, through: 60, by: 5) {
            let label = UILabel()
            label.text = "\(minute)"
            label.font = .custom(weight: .medium, size: 14)
            label.textColor = gaugeColor
            label.textAlignment = .center
            addSubview(label)
            timeLabels.append(label)
        }
    }

    private func setupGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)

        impactFeedback.prepare()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let imageSize: CGFloat = radius * 2
        imageMaskLayer.frame = CGRect(
            x: (bounds.width - imageSize) / 2,
            y: (bounds.height - imageSize) / 2,
            width: imageSize,
            height: imageSize
        )

        if let originalPath = boundaryPath {
            normalizedBoundaryPath = normalizePath(originalPath, to: radius)
            dump(originalPath)
            dump(normalizedBoundaryPath)
        }

        drawTickMarks()
        updateTimeLabelsPosition()
        updateUI()
    }

    // MARK: - Path Normalization
    private func normalizePath(_ path: UIBezierPath, to radius: CGFloat) -> UIBezierPath {
        let pathBounds = path.bounds
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let scaleFactor = (radius * 1.5) / max(pathBounds.width, pathBounds.height)

        let transform = CGAffineTransform.identity
            .translatedBy(x: center.x, y: center.y)
            .scaledBy(x: scaleFactor, y: scaleFactor)
            .translatedBy(x: -pathBounds.midX, y: -pathBounds.midY)

        let normalizedPath = UIBezierPath(cgPath: path.cgPath)
        normalizedPath.apply(transform)

        return normalizedPath
    }

    // MARK: - Drawing
    private func drawTickMarks() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath()

        for minute in minMinutes...maxMinutes {
            let angle = angleForMinute(minute)
            let isMajorTick = minute % 5 == 0

            let tickLength: CGFloat = isMajorTick ? 15 : 8

            let startRadius = radius
            let endRadius = radius + tickLength

            let startPoint = pointOnCircle(center: center, radius: startRadius, angle: angle)
            let endPoint = pointOnCircle(center: center, radius: endRadius, angle: angle)

            path.move(to: startPoint)
            path.addLine(to: endPoint)
        }

        tickMarksLayer.path = path.cgPath
        tickMarksLayer.lineWidth = 1
    }

    private func updateTimeLabelsPosition() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        for (index, label) in timeLabels.enumerated() {
            let minute = (index + 1) * 5
            let angle = angleForMinute(minute)
            let labelRadius = radius + 30
            let labelCenter = pointOnCircle(center: center, radius: labelRadius, angle: angle)

            label.frame = CGRect(
                x: labelCenter.x - 20,
                y: labelCenter.y - 10,
                width: 40,
                height: 20
            )
        }
    }

    private func updateUI() {
        updateGauge()
        updateHandle()
    }

    private func updateGauge() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle = angleForMinute(0)
        let endAngle = angleForMinute(selectedMinutes)

        let path = UIBezierPath()
        path.move(to: center)
        path.addLine(to: pointOnCircle(center: center, radius: radius, angle: startAngle))
        path.addArc(
            withCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        path.close()

        gaugeLayer.path = path.cgPath
    }

    private func updateHandle() {
        let handleCenter: CGPoint
        if let path = normalizedBoundaryPath {
            // 라디안 기반 계산으로 정확한 각도 매핑
            // angleForMinute와 동일한 방식 사용
            let angle = angleForMinute(selectedMinutes)

            // 라디안을 0-1 범위의 progress로 변환
            // -π/2 (12시) ~ 3π/2 (12시로 복귀) → 0 ~ 1
            let normalizedAngle = angle + .pi / 2  // 0부터 시작하도록 조정
            let progress = normalizedAngle / (2 * .pi)

            print("Minutes: \(selectedMinutes), Angle: \(angle * 180 / .pi)°, Progress: \(progress * 100)%")

            handleCenter = path.point(at: progress)
        } else {
            // Fallback: 원형
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let angle = angleForMinute(selectedMinutes)
            handleCenter = pointOnCircle(center: center, radius: radius, angle: angle)
        }

        // 15분 단위일 때 축 정렬 보정
        var adjustedCenter = handleCenter
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        switch selectedMinutes {
        case 15:
            // 3시 방향 (오른쪽) - y축을 중심에 고정
            adjustedCenter.y = center.y
        case 30:
            // 6시 방향 (아래) - x축을 중심에 고정
            adjustedCenter.x = center.x
        case 45:
            // 9시 방향 (왼쪽) - y축을 중심에 고정
            adjustedCenter.y = center.y
        case 60:
            // 12시 방향 (위) - x축을 중심에 고정
            adjustedCenter.x = center.x
        default:
            break
        }

        handleView.frame = CGRect(
            x: adjustedCenter.x - handleSize / 2,
            y: adjustedCenter.y - handleSize / 2,
            width: handleSize,
            height: handleSize
        )
    }

    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let dx = location.x - center.x
        let dy = location.y - center.y
        var angle = atan2(dy, dx)

        angle = angle + .pi / 2
        if angle < 0 {
            angle += 2 * .pi
        }

        var minutes = Int(round((angle / (2 * .pi)) * 60))
        if minutes == 0 {
            minutes = 60
        }
        minutes = max(minMinutes, min(maxMinutes, minutes))

        if minutes != selectedMinutes {
            selectedMinutes = minutes
            impactFeedback.impactOccurred()
            impactFeedback.prepare()
        }

        if gesture.state == .ended {
        }
    }

    // MARK: - Helper Methods
    private func angleForMinute(_ minute: Int) -> CGFloat {
        let normalized = CGFloat(minute) / 60.0
        return normalized * 2 * .pi - .pi / 2
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        return CGPoint(
            x: center.x + radius * cos(angle),
            y: center.y + radius * sin(angle)
        )
    }
}
