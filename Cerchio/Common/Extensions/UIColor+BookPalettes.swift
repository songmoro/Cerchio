//
//  UIColor+BookPalettes.swift
//  Cerchio
//
//  Created by 송재훈 on 10/22/25.
//

import UIKit

extension UIColor {
    static let softNeutralPalette: [UIColor] = [
        UIColor(red: 0.93, green: 0.91, blue: 0.87, alpha: 1.0),
        UIColor(red: 0.90, green: 0.88, blue: 0.84, alpha: 1.0),
        UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0),
        UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0),
        UIColor(red: 0.86, green: 0.83, blue: 0.81, alpha: 1.0),
        UIColor(red: 0.84, green: 0.81, blue: 0.79, alpha: 1.0),
        UIColor(red: 0.84, green: 0.87, blue: 0.89, alpha: 1.0),
        UIColor(red: 0.86, green: 0.88, blue: 0.90, alpha: 1.0)
    ]

    static let warmEarthPalette: [UIColor] = [
        UIColor(red: 0.91, green: 0.82, blue: 0.75, alpha: 1.0),
        UIColor(red: 0.88, green: 0.78, blue: 0.71, alpha: 1.0),
        UIColor(red: 0.93, green: 0.89, blue: 0.82, alpha: 1.0),
        UIColor(red: 0.90, green: 0.86, blue: 0.79, alpha: 1.0),
        UIColor(red: 0.89, green: 0.84, blue: 0.75, alpha: 1.0),
        UIColor(red: 0.86, green: 0.81, blue: 0.72, alpha: 1.0),
        UIColor(red: 0.87, green: 0.80, blue: 0.74, alpha: 1.0),
        UIColor(red: 0.84, green: 0.77, blue: 0.71, alpha: 1.0)
    ]

    static let coolMutedPalette: [UIColor] = [
        UIColor(red: 0.88, green: 0.93, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.85, green: 0.90, blue: 0.87, alpha: 1.0),
        UIColor(red: 0.90, green: 0.88, blue: 0.93, alpha: 1.0),
        UIColor(red: 0.87, green: 0.85, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.87, green: 0.91, blue: 0.94, alpha: 1.0),
        UIColor(red: 0.84, green: 0.88, blue: 0.91, alpha: 1.0),
        UIColor(red: 0.93, green: 0.88, blue: 0.89, alpha: 1.0),
        UIColor(red: 0.90, green: 0.85, blue: 0.86, alpha: 1.0)
    ]

    // MARK: - 4. 빈티지 종이 질감
    static let vintagePaperPalette: [UIColor] = [
        UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1.0),
        UIColor(red: 0.95, green: 0.93, blue: 0.89, alpha: 1.0),
        UIColor(red: 0.96, green: 0.94, blue: 0.88, alpha: 1.0),
        UIColor(red: 0.94, green: 0.92, blue: 0.86, alpha: 1.0),
        UIColor(red: 0.92, green: 0.89, blue: 0.84, alpha: 1.0),
        UIColor(red: 0.90, green: 0.87, blue: 0.82, alpha: 1.0),
        UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1.0),
        UIColor(red: 0.92, green: 0.90, blue: 0.86, alpha: 1.0)
    ]

    static let modernMinimalistPalette: [UIColor] = [
        UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0),
        UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1.0),
        UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0),
        UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.0),
        UIColor(red: 0.91, green: 0.93, blue: 0.95, alpha: 1.0),
        UIColor(red: 0.89, green: 0.91, blue: 0.93, alpha: 1.0),
        UIColor(red: 0.93, green: 0.93, blue: 0.91, alpha: 1.0),
        UIColor(red: 0.91, green: 0.91, blue: 0.89, alpha: 1.0)
    ]

    // MARK: - 현재 팔레트
    static var currentBookPalette: [UIColor] {
        return modernMinimalistPalette
    }

    static func randomBookColor() -> UIColor {
        return currentBookPalette.randomElement() ?? .systemGray5
    }
}
