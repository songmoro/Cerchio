//
//  HapticFeedbackManager.swift
//  Cerchio
//
//  Created by 송재훈 Code
//

import UIKit

/// Centralized manager for haptic feedback throughout the app
/// Provides consistent haptic feedback for user interactions
final class HapticFeedbackManager {

    // MARK: - Singleton

    static let shared = HapticFeedbackManager()

    // MARK: - Properties

    private let impactGenerator: UIImpactFeedbackGenerator
    private let selectionGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator

    // MARK: - Initialization

    private init() {
        self.impactGenerator = UIImpactFeedbackGenerator(style: .light)
        self.selectionGenerator = UISelectionFeedbackGenerator()
        self.notificationGenerator = UINotificationFeedbackGenerator()

        impactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Public Methods

    /// Triggers a light impact haptic feedback
    /// Use for general button taps and standard interactions
    func impact() {
        impactGenerator.impactOccurred()
        impactGenerator.prepare() // Re-prepare for next use
    }

    /// Triggers a selection haptic feedback
    /// Use for menu item selections and picker value changes
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare() // Re-prepare for next use
    }

    /// Triggers a success notification haptic feedback
    /// Use for successful operations (save, delete confirmation, etc.)
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    /// Triggers a warning notification haptic feedback
    /// Use for warning states or actions requiring attention
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    /// Triggers an error notification haptic feedback
    /// Use for failed operations or error states
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}
