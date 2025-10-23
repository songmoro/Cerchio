//
//  ImageTimerPickerView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import SnapKit

final class ImageTimerPickerView: UIView {

    private let imageMaskLayer = CALayer()
    private let gaugeLayer = CAShapeLayer()
    private let tickMarksLayer = CAShapeLayer()
    private let handleView = UIView()
    private var timeLabels: [UILabel] = []

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

    private let gaugeColor: UIColor
    private let tickColor: UIColor
    private let radius: CGFloat
    private let handleSize: CGFloat = 20

    init(
        maskImage: UIImage? = nil,
        maskImageName: String? = nil,
        gaugeColor: UIColor = .forestGreen,
        radius: CGFloat = 120,
        frame: CGRect = .zero
    ) {
        self.gaugeColor = gaugeColor
        self.tickColor = gaugeColor.withAlphaComponent(0.3)
        self.radius = radius

        super.init(frame: frame)

        setupUI(maskImage: maskImage, maskImageName: maskImageName)
        setupGesture()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

        drawTickMarks()
        updateTimeLabelsPosition()
        updateUI()
    }

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
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let angle = angleForMinute(selectedMinutes)
        let handleCenter = pointOnCircle(center: center, radius: radius, angle: angle)

        handleView.frame = CGRect(
            x: handleCenter.x - handleSize / 2,
            y: handleCenter.y - handleSize / 2,
            width: handleSize,
            height: handleSize
        )
    }

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
