//
//  CircleTabBarConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation

enum CircleTabBarConstants {

    // MARK: - Animation
    enum Animation {
        static let floatingOffset: CGFloat = 8
        static let duration: Double = 0.3
        static let delay: Double = 0.01
    }

    // MARK: - Dimensions
    enum Dimensions {
        // Tab Bar
        static let tabBarHeight: CGFloat = 66
        static let hostingControllerHeight: CGFloat = 58

        // Icon
        static let iconSize: CGFloat = 24

        // Background & Mask
        static let floatingBackgroundSize: CGFloat = 40
        static let maskSize: CGFloat = 48

        // Spacing
        static let iconSpacing: CGFloat = 4

        // Padding
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 24

        // Layout Calculations
        static let screenInset: CGFloat = 32
        static let buttonHalfWidth: CGFloat = 12
        static let buttonY: CGFloat = 20
        static let buttonSize: CGFloat = 24
        static let floatingAdjustmentY: CGFloat = 18
    }

    // MARK: - Shadow
    enum Shadow {
        static let radius: CGFloat = 4
        static let offsetX: CGFloat = 0
        static let offsetY: CGFloat = 2
        static let opacity: Double = 0.1

        static let tabBarRadius: CGFloat = 8
        static let tabBarOffsetX: CGFloat = 0
        static let tabBarOffsetY: CGFloat = -2
    }

    // MARK: - Coordinate Space
    enum CoordinateSpace {
        static let tabBar = "TabBarCoordinate"
    }
}
