//
//  CircleTabBarConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation

struct CircleTabBarConstants {

    // MARK: - Animation
    struct Animation {
        static let floatingOffset: CGFloat = 8
        static let duration: Double = 0.3
        static let delay: Double = 0.01
    }

    // MARK: - Dimensions
    struct Dimensions {
        // Tab Bar
        static let tabBarHeight: CGFloat = 58

        // Icon
        static let iconSize: CGFloat = 24

        // Background & Mask
        static let floatingBackgroundSize: CGFloat = 40
        static let maskSize: CGFloat = 48

        // Spacing
        static let iconSpacing: CGFloat = 4
    }

    // MARK: - Shadow
    struct Shadow {
        static let radius: CGFloat = 4
        static let offsetX: CGFloat = 0
        static let offsetY: CGFloat = 2
        static let opacity: Double = 0.1

        static let tabBarRadius: CGFloat = 8
        static let tabBarOffsetX: CGFloat = 0
        static let tabBarOffsetY: CGFloat = -2
    }

    // MARK: - Coordinate Space
    struct CoordinateSpace {
        static let tabBar = "TabBarCoordinate"
    }
}
