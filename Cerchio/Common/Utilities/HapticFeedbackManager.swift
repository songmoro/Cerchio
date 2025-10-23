//
//  HapticFeedbackManager.swift
//  Cerchio
//
//  Created by 송재훈 Code
//

import UIKit

final class HapticFeedbackManager {

    static let shared = HapticFeedbackManager()

    private let impactGenerator: UIImpactFeedbackGenerator
    private let selectionGenerator: UISelectionFeedbackGenerator
    private let notificationGenerator: UINotificationFeedbackGenerator

    private init() {
        self.impactGenerator = UIImpactFeedbackGenerator(style: .light)
        self.selectionGenerator = UISelectionFeedbackGenerator()
        self.notificationGenerator = UINotificationFeedbackGenerator()

        impactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    func impact() {
        impactGenerator.impactOccurred()
        impactGenerator.prepare()
    }

    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
}
