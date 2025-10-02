//
//  InsetTextView.swift
//  Cerchio
//
//  Created by Claude Code on 10/2/25.
//

import UIKit

/// 커스텀 인셋과 플레이스홀더를 가진 UITextView
final class InsetTextView: UITextView {
    var textInsets: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) {
        didSet {
            setNeedsLayout()
        }
    }

    var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            setNeedsLayout()
        }
    }

    var placeholderColor: UIColor = .placeholderText {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .placeholderText
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }

    private func setupPlaceholder() {
        addSubview(placeholderLabel)
        placeholderLabel.isHidden = !text.isEmpty

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }

    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }

    override var text: String! {
        didSet {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }

    override var contentInset: UIEdgeInsets {
        get {
            return super.contentInset
        }
        set {
            super.contentInset = newValue
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textContainerInset = textInsets

        // 플레이스홀더 위치를 textContainerInset과 lineFragmentPadding에 맞춤
        let x = textInsets.left + textContainer.lineFragmentPadding
        let y = textInsets.top
        let width = bounds.width - textInsets.left - textInsets.right - (textContainer.lineFragmentPadding * 2)
        let height = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height

        placeholderLabel.frame = CGRect(x: x, y: y, width: width, height: height)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
