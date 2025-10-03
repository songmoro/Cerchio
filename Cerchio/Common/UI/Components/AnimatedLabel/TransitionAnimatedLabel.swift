//
//  TransitionAnimatedLabel.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit

/// UIView.transition을 사용한 간단한 텍스트 애니메이션
final class TransitionAnimatedLabel: UILabel {

    var animationDuration: TimeInterval = 0.3
    var animationOptions: UIView.AnimationOptions = .transitionFlipFromTop

    override var text: String? {
        didSet {
            guard text != oldValue else { return }
            animateTextChange()
        }
    }

    private func animateTextChange() {
        UIView.transition(
            with: self,
            duration: animationDuration,
            options: animationOptions,
            animations: nil
        )
    }

    /// 텍스트를 애니메이션과 함께 설정
    func setText(_ newText: String?, animated: Bool = true) {
        if animated {
            UIView.transition(
                with: self,
                duration: animationDuration,
                options: animationOptions
            ) {
                super.text = newText
            }
        } else {
            super.text = newText
        }
    }
}
