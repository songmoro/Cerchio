//
//  ViewHighlightEffect.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit

struct ViewHighlightEffect: OptionSet {
    let rawValue: Int

    static let none = ViewHighlightEffect([])

    static let scale = ViewHighlightEffect(rawValue: 1 << 0)

    static let contextualRotation = ViewHighlightEffect(rawValue: 1 << 1)

    static let customRotation = ViewHighlightEffect(rawValue: 1 << 2)

    static let `default`: ViewHighlightEffect = .none

    static let scaleAndRotation: ViewHighlightEffect = [.scale, .contextualRotation]

    var scaleMultiplier: CGFloat {
        contains(.scale) ? CircularMenuConstants.Layout.scaleMultiplier : 1.0
    }

    var rotationAngle: CGFloat {
        contains(.contextualRotation) || contains(.customRotation) ? 5.0 : 0.0
    }

    func asTransform(viewCenter: CGPoint, screenCenter: CGPoint, customAngle: CGFloat? = nil) -> CGAffineTransform {
        var transform = CGAffineTransform.identity

        if contains(.scale) {
            transform = transform.scaledBy(x: scaleMultiplier, y: scaleMultiplier)
        }

        if contains(.contextualRotation) {
            let isLeftSide = viewCenter.x < screenCenter.x
            let degrees = isLeftSide ? -rotationAngle : rotationAngle
            let radians = degrees * .pi / 180
            transform = transform.rotated(by: radians)
        } else if contains(.customRotation), let angle = customAngle {
            let radians = angle * .pi / 180
            transform = transform.rotated(by: radians)
        }

        return transform
    }
}

struct ViewHighlightConfiguration {
    let effect: ViewHighlightEffect

    let animationDuration: TimeInterval

    let cornerRadius: CGFloat?

    let cornerRadiusMultiplier: CGFloat

    let shadowColor: UIColor
    let shadowOpacity: Float
    let shadowOffset: CGSize
    let shadowRadius: CGFloat

    let hideOriginalView: Bool

    let customRotationAngle: CGFloat?

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
