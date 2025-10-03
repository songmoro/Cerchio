//
//  CATransitionAnimatedLabel.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit

/// CATransition을 사용한 세밀한 텍스트 애니메이션
final class CATransitionAnimatedLabel: UILabel {

    enum TransitionType {
        case push
        case moveIn
        case reveal
        case fade

        var caType: CATransitionType {
            switch self {
            case .push: return .push
            case .moveIn: return .moveIn
            case .reveal: return .reveal
            case .fade: return .fade
            }
        }
    }

    enum TransitionSubtype {
        case fromTop
        case fromBottom
        case fromLeft
        case fromRight

        var caSubtype: CATransitionSubtype {
            switch self {
            case .fromTop: return .fromTop
            case .fromBottom: return .fromBottom
            case .fromLeft: return .fromLeft
            case .fromRight: return .fromRight
            }
        }
    }

    var animationDuration: TimeInterval = 0.2
    var transitionType: TransitionType = .push
    var transitionSubtype: TransitionSubtype = .fromTop
    var timingFunctionName: CAMediaTimingFunctionName = .easeInEaseOut

    override var text: String? {
        didSet {
            guard text != oldValue else { return }
            animateTextChange()
        }
    }

    private func animateTextChange() {
        let transition = CATransition()
        transition.type = transitionType.caType
        transition.subtype = transitionSubtype.caSubtype
        transition.duration = animationDuration
        transition.timingFunction = CAMediaTimingFunction(name: timingFunctionName)

        layer.add(transition, forKey: "textChange")
    }

    /// 텍스트를 애니메이션과 함께 설정
    func setText(_ newText: String?, animated: Bool = true) {
        if animated {
            let transition = CATransition()
            transition.type = transitionType.caType
            transition.subtype = transitionSubtype.caSubtype
            transition.duration = animationDuration
            transition.timingFunction = CAMediaTimingFunction(name: timingFunctionName)

            layer.add(transition, forKey: "textChange")
            super.text = newText
        } else {
            super.text = newText
        }
    }
}
