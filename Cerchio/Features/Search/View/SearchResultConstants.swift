//
//  SearchResultConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation

struct SearchResultConstants {

    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 8
        static let cellHorizontalInset: CGFloat = 16
        static let cellVerticalInset: CGFloat = 12
        static let imageWidth: CGFloat = 60
        static let imageHeight: CGFloat = 80
        static let buttonWidth: CGFloat = 60
        static let buttonHeight: CGFloat = 32
        static let stackSpacing: CGFloat = 4
        static let contentSpacing: CGFloat = 12
    }

    // MARK: - Typography
    struct Typography {
        static let titleFontSize: CGFloat = 16
        static let authorFontSize: CGFloat = 14
        static let buttonFontSize: CGFloat = 14
    }

    // MARK: - Animation
    struct Animation {
        static let buttonAnimationDuration: TimeInterval = 0.1
        static let buttonScaleDown: CGFloat = 0.95
    }
}