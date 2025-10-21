//
//  UIColor+NeutralPastel.swift
//  Cerchio
//
//  Created by Claude on 10/22/25.
//

import UIKit

extension UIColor {
    static let neutralPastelColors: [UIColor] = [
        // Beige tones
        UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1.0),
        UIColor(red: 0.90, green: 0.88, blue: 0.84, alpha: 1.0),
        // Gray tones
        UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0),
        UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0),
        // Taupe tones
        UIColor(red: 0.86, green: 0.83, blue: 0.81, alpha: 1.0),
        UIColor(red: 0.84, green: 0.81, blue: 0.79, alpha: 1.0),
        // Blue-gray tones
        UIColor(red: 0.84, green: 0.87, blue: 0.89, alpha: 1.0),
        UIColor(red: 0.86, green: 0.88, blue: 0.90, alpha: 1.0)
    ]

    static func randomNeutralPastel() -> UIColor {
        return neutralPastelColors.randomElement() ?? .systemGray5
    }
}
