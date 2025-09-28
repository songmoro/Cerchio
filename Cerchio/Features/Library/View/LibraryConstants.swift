//
//  LibraryConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation

struct LibraryConstants {

    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 8
        static let cellInset: CGFloat = 8
        static let stackOffset: CGFloat = 4
        static let aspectRatio: CGFloat = 4.0/3.0
    }

    // MARK: - Typography
    struct Typography {
        static let titleFontSize: CGFloat = 14
        static let authorFontSize: CGFloat = 14
    }

    // MARK: - Height Calculation
    struct HeightCalculation {
        static let defaultHeight: CGFloat = 200
        static let screenHeightDivider: CGFloat = 3
        static let titleCharacterDivider: Int = 18
        static let titleLineHeight: Int = 14
        static let authorCharacterDivider: Int = 20
        static let authorLineHeight: Int = 12
    }

    // MARK: - Gesture
    struct Gesture {
        static let minimumPressDuration: TimeInterval = 0.5
    }
}