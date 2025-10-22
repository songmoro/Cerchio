//
//  CustomSlideAnimatedLabel.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit

/// SwiftUI 스타일의 커스텀 슬라이드 애니메이션 (위에서 아래로)
final class CustomSlideAnimatedLabel: UIView {

    private let currentLabel = UILabel()
    private let nextLabel = UILabel()

    var font: UIFont? {
        didSet {
            currentLabel.font = font
            nextLabel.font = font
        }
    }

    var textColor: UIColor? {
        didSet {
            currentLabel.textColor = textColor
            nextLabel.textColor = textColor
        }
    }

    var textAlignment: NSTextAlignment = .center {
        didSet {
            currentLabel.textAlignment = textAlignment
            nextLabel.textAlignment = textAlignment
        }
    }

    var text: String? {
        get { currentLabel.text }
        set { setText(newValue, animated: true) }
    }

    var animationDuration: TimeInterval = 0.3
    var slideDistance: CGFloat = 30

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true

        currentLabel.textAlignment = .center
        addSubview(currentLabel)

        nextLabel.textAlignment = .center
        nextLabel.alpha = 0
        addSubview(nextLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        currentLabel.frame = bounds
        nextLabel.frame = bounds
    }

    /// 텍스트를 애니메이션과 함께 설정
    func setText(_ newText: String?, animated: Bool = true) {
        guard newText != currentLabel.text else { return }

        if !animated {
            currentLabel.text = newText
            return
        }

        nextLabel.text = newText
        nextLabel.alpha = 1
        nextLabel.transform = CGAffineTransform(translationX: 0, y: -slideDistance)

        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: [.curveEaseOut]
        ) {
            self.nextLabel.transform = .identity

            self.currentLabel.transform = CGAffineTransform(translationX: 0, y: self.slideDistance)
            self.currentLabel.alpha = 0
        } completion: { _ in
            self.currentLabel.text = newText
            self.currentLabel.alpha = 1
            self.currentLabel.transform = .identity

            self.nextLabel.alpha = 0
            self.nextLabel.transform = .identity
        }
    }
}
