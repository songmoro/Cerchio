//
//  ViewHighlightEffect.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit

/// Defines the visual effects applied to a view when highlighted using OptionSet pattern
struct ViewHighlightEffect: OptionSet {
    let rawValue: Int

    /// No effect - view remains unchanged
    static let none = ViewHighlightEffect([])

    /// Scale the view
    static let scale = ViewHighlightEffect(rawValue: 1 << 0)

    /// Rotate the view contextually based on screen position
    static let contextualRotation = ViewHighlightEffect(rawValue: 1 << 1)

    /// Custom rotation (both sides rotate same direction)
    static let customRotation = ViewHighlightEffect(rawValue: 1 << 2)

    /// Default effect: no transformations
    static let `default`: ViewHighlightEffect = .none

    /// Scale and rotation combined
    static let scaleAndRotation: ViewHighlightEffect = [.scale, .contextualRotation]

    // MARK: - Effect Parameters
    var scaleMultiplier: CGFloat {
        contains(.scale) ? CircularMenuConstants.Layout.scaleMultiplier : 1.0
    }

    var rotationAngle: CGFloat {
        contains(.contextualRotation) || contains(.customRotation) ? 5.0 : 0.0 // degrees
    }

    /// Convert to CGAffineTransform
    func asTransform(viewCenter: CGPoint, screenCenter: CGPoint, customAngle: CGFloat? = nil) -> CGAffineTransform {
        var transform = CGAffineTransform.identity

        // Apply scale
        if contains(.scale) {
            transform = transform.scaledBy(x: scaleMultiplier, y: scaleMultiplier)
        }

        // Apply rotation
        if contains(.contextualRotation) {
            // 기본 contextual rotation은 좌우 구분
            let isLeftSide = viewCenter.x < screenCenter.x
            let degrees = isLeftSide ? -rotationAngle : rotationAngle
            let radians = degrees * .pi / 180
            transform = transform.rotated(by: radians)
        } else if contains(.customRotation), let angle = customAngle {
            // 커스텀 각도는 양쪽 동일하게 적용 (양수 = 위로)
            let radians = angle * .pi / 180
            transform = transform.rotated(by: radians)
        }

        return transform
    }
}

/// Configuration for view highlight behavior
struct ViewHighlightConfiguration {
    /// Visual effects to apply when highlighted
    let effect: ViewHighlightEffect

    /// Duration of the highlight animation
    let animationDuration: TimeInterval

    /// Corner radius to apply (if nil, uses original view's corner radius)
    let cornerRadius: CGFloat?

    /// Corner radius multiplier (applied proportionally to scale)
    let cornerRadiusMultiplier: CGFloat

    /// Shadow configuration
    let shadowColor: UIColor
    let shadowOpacity: Float
    let shadowOffset: CGSize
    let shadowRadius: CGFloat

    /// Whether to hide the original view during highlight
    let hideOriginalView: Bool

    /// Custom rotation angle (for customRotation effect)
    let customRotationAngle: CGFloat?

    /// Default configuration - no effects applied
    static var `default`: ViewHighlightConfiguration {
        ViewHighlightConfiguration(
            effect: .default,
            animationDuration: CircularMenuConstants.Animation.duration,
            cornerRadius: CircularMenuConstants.Layout.cornerRadius,
            cornerRadiusMultiplier: 1.0,
            shadowColor: .clear,
            shadowOpacity: .zero,
            shadowOffset: .zero,
            shadowRadius: .zero,
            hideOriginalView: true,
            customRotationAngle: nil
        )
    }

    /// Configuration with scale only
    static var withScale: ViewHighlightConfiguration {
        ViewHighlightConfiguration(
            effect: .scale,
            animationDuration: CircularMenuConstants.Animation.duration,
            cornerRadius: CircularMenuConstants.Layout.cornerRadius,
            cornerRadiusMultiplier: CircularMenuConstants.Layout.scaleMultiplier,
            shadowColor: .clear,
            shadowOpacity: .zero,
            shadowOffset: .zero,
            shadowRadius: .zero,
            hideOriginalView: true,
            customRotationAngle: nil
        )
    }

    /// Configuration with contextual rotation based on screen position
    /// Rotation direction is automatically determined: left side tilts left, right side tilts right
    static func withContextualRotation() -> ViewHighlightConfiguration {
        ViewHighlightConfiguration(
            effect: .contextualRotation,
            animationDuration: CircularMenuConstants.Animation.duration,
            cornerRadius: CircularMenuConstants.Layout.cornerRadius,
            cornerRadiusMultiplier: 1.0,
            shadowColor: .clear,
            shadowOpacity: .zero,
            shadowOffset: .zero,
            shadowRadius: .zero,
            hideOriginalView: true,
            customRotationAngle: nil
        )
    }

    /// Configuration with custom rotation angle (positive = up, negative = down)
    static func withCustomRotation(angle: CGFloat) -> ViewHighlightConfiguration {
        ViewHighlightConfiguration(
            effect: .customRotation,
            animationDuration: CircularMenuConstants.Animation.duration,
            cornerRadius: CircularMenuConstants.Layout.cornerRadius,
            cornerRadiusMultiplier: 1.0,
            shadowColor: .clear,
            shadowOpacity: .zero,
            shadowOffset: .zero,
            shadowRadius: .zero,
            hideOriginalView: true,
            customRotationAngle: angle
        )
    }

    /// Configuration with scale and contextual rotation
    static var withScaleAndRotation: ViewHighlightConfiguration {
        ViewHighlightConfiguration(
            effect: .scaleAndRotation,
            animationDuration: CircularMenuConstants.Animation.duration,
            cornerRadius: CircularMenuConstants.Layout.cornerRadius,
            cornerRadiusMultiplier: CircularMenuConstants.Layout.scaleMultiplier,
            shadowColor: .clear,
            shadowOpacity: .zero,
            shadowOffset: .zero,
            shadowRadius: .zero,
            hideOriginalView: true,
            customRotationAngle: nil
        )
    }
}
