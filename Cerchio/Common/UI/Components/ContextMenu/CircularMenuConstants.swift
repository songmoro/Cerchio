//
//  CircularMenuConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit

enum CircularMenuConstants {

    // MARK: - Layout
    enum Layout {
        static let buttonSize: CGFloat = 50
        static let menuRadius: CGFloat = 100
        static let scaleMultiplier: CGFloat = 1.0
        static let cornerRadius: CGFloat = 8
        static let labelMargin: CGFloat = 40
        static let shadowOffset = CGSize(width: 0, height: 0)
        static let shadowRadius: CGFloat = 1
        static let buttonShadowOffset = CGSize(width: 0, height: 0.5)
        static let buttonShadowRadius: CGFloat = 0.2
        static let selectedViewScale: CGFloat = 1.2
        static let radiansConversion: CGFloat = 180
    }

    // MARK: - Animation
    enum Animation {
        static let duration: TimeInterval = 0.3
        static let labelDuration: TimeInterval = 0.2
        static let buttonAnimationDuration: TimeInterval = 0.1
        static let presentationDelay: TimeInterval = 0.3
        static let initialScale: CGFloat = 0.1
        static let labelScale: CGFloat = 0.8
        static let buttonHighlightScale: CGFloat = 0.95
    }

    // MARK: - Angles
    enum Angles {
        static let arcAngle: CGFloat = CGFloat.pi
        static let angleStep: CGFloat = 0.6
        static let tiltAngleLeft: CGFloat = -5
        static let tiltAngleRight: CGFloat = 5
        static let quarterPi: CGFloat = CGFloat.pi / 4
        static let halfPi: CGFloat = CGFloat.pi / 2
        static let threeQuarterPi: CGFloat = 3 * CGFloat.pi / 4
        static let negativeQuarterPi: CGFloat = -CGFloat.pi / 4
        static let negativeThreeQuarterPi: CGFloat = -3 * CGFloat.pi / 4
    }

    // MARK: - Counts
    enum Counts {
        static let singleButton: Int = 1
        static let minButtonCount: Int = 0
        static let divisionFactor: CGFloat = 2
    }

    // MARK: - Colors
    enum Colors {
        static let backgroundAlpha: CGFloat = 0.9
        static let shadowOpacity: Float = 0.2
        static let tagBackgroundAlpha: CGFloat = 0.1
        static let buttonShadowOpacity: Float = 0.2
        static let hiddenAlpha: CGFloat = 0
        static let visibleAlpha: CGFloat = 1
        static let debugAlpha: CGFloat = 0.3
    }

    // MARK: - Typography
    enum Typography {
        static let labelFontSize: CGFloat = 24
    }

    // MARK: - Position Ratios
    struct PositionRatios {
        static let leftBoundaryRatio: CGFloat = 0.3
        static let rightBoundaryRatio: CGFloat = 1.7
        static let topBoundaryRatio: CGFloat = 0.3
        static let bottomBoundaryRatio: CGFloat = 1.7
    }
}