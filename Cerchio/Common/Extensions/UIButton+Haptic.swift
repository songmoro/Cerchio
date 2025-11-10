//
//  UIButton+Haptic.swift
//  Cerchio
//
//  Created by 송재훈 Code
//

import UIKit

extension UIButton {
    func enableHapticFeedback() {
        addTarget(self, action: #selector(triggerHaptic), for: .touchUpInside)
    }

    @objc private func triggerHaptic() {
        HapticFeedbackManager.shared.impact()
    }
}
