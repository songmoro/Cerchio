//
//  UIButton+Haptic.swift
//  Cerchio
//
//  Created by 송재훈 Code
//

import UIKit

extension UIButton {

    /// Adds haptic feedback to the button's existing target-action
    /// This method wraps the existing action with haptic feedback
    ///
    /// Example usage:
    /// ```swift
    /// button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    /// button.enableHapticFeedback()
    /// ```
    func enableHapticFeedback() {
        addTarget(self, action: #selector(triggerHaptic), for: .touchUpInside)
    }

    @objc private func triggerHaptic() {
        HapticFeedbackManager.shared.impact()
    }
}
