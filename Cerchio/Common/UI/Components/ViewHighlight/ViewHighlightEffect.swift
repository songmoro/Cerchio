//
//  ViewHighlightEffect.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit

/// Defines the visual effects applied to a view when highlighted
enum ViewHighlightEffect {
    /// Scale the view by a multiplier (e.g., 1.2 for 120% size)
    case scale(CGFloat)

    /// Rotate the view by degrees (positive = clockwise, negative = counter-clockwise)
    case rotation(degrees: CGFloat)

    /// Apply a custom transform directly
    case transform(CGAffineTransform)

    /// Combine multiple effects
    case combined([ViewHighlightEffect])

    /// Default effect: 1.2x scale with contextual rotation
    static var `default`: ViewHighlightEffect {
        .combined([.scale(1.2), .rotation(degrees: 0)])
    }

    /// Convert to CGAffineTransform
    func asTransform(viewCenter: CGPoint, screenCenter: CGPoint) -> CGAffineTransform {
        switch self {
        case .scale(let multiplier):
            return CGAffineTransform(scaleX: multiplier, y: multiplier)

        case .rotation(let degrees):
            let radians = degrees * .pi / 180
            return CGAffineTransform(rotationAngle: radians)

        case .transform(let transform):
            return transform

        case .combined(let effects):
            return effects.reduce(.identity) { result, effect in
                result.concatenating(effect.asTransform(viewCenter: viewCenter, screenCenter: screenCenter))
            }
        }
    }
}

/// Configuration for view highlight behavior
struct ViewHighlightConfiguration {
    /// Visual effects to apply when highlighted
    let effect: ViewHighlightEffect

    /// Duration of the highlight animation
    let animationDuration: TimeInterval

    /// Corner radius multiplier (applied proportionally to scale)
    let cornerRadiusMultiplier: CGFloat

    /// Shadow configuration
    let shadowColor: UIColor
    let shadowOpacity: Float
    let shadowOffset: CGSize
    let shadowRadius: CGFloat

    /// Whether to hide the original view during highlight
    let hideOriginalView: Bool

    /// Default configuration with scale and contextual rotation
    static var `default`: ViewHighlightConfiguration {
        ViewHighlightConfiguration(
            effect: .combined([
                .scale(CircularMenuConstants.Layout.scaleMultiplier),
                .rotation(degrees: 0) // Will be computed contextually
            ]),
            animationDuration: CircularMenuConstants.Animation.duration,
            cornerRadiusMultiplier: CircularMenuConstants.Layout.scaleMultiplier,
            shadowColor: .black,
            shadowOpacity: CircularMenuConstants.Colors.shadowOpacity,
            shadowOffset: CircularMenuConstants.Layout.shadowOffset,
            shadowRadius: CircularMenuConstants.Layout.shadowRadius,
            hideOriginalView: true
        )
    }

    /// Configuration with contextual rotation based on screen position
    static func withContextualRotation(tiltAngle: CGFloat = 5.0) -> ViewHighlightConfiguration {
        var config = ViewHighlightConfiguration.default
        return ViewHighlightConfiguration(
            effect: .combined([
                .scale(CircularMenuConstants.Layout.scaleMultiplier),
                .rotation(degrees: tiltAngle) // Will be determined by screen position
            ]),
            animationDuration: config.animationDuration,
            cornerRadiusMultiplier: config.cornerRadiusMultiplier,
            shadowColor: config.shadowColor,
            shadowOpacity: config.shadowOpacity,
            shadowOffset: config.shadowOffset,
            shadowRadius: config.shadowRadius,
            hideOriginalView: config.hideOriginalView
        )
    }
}