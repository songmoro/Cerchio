//
//  LibraryConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import Foundation

enum LibraryConstants {

    enum Layout {
        static let cornerRadius: CGFloat = 8
        static let cellInset: CGFloat = 8
        static let stackOffset: CGFloat = 4
        static let aspectRatio: CGFloat = 4.0/3.0
        static let backgroundCornerRadius: CGFloat = 12
        static let backgroundImagePadding: CGFloat = 8
    }

    enum Typography {
        static let titleFontSize: CGFloat = 14
        static let authorFontSize: CGFloat = 14
        static let multilineLabel: Int = 0
    }

    enum HeightCalculation {
        static let defaultHeight: CGFloat = 200
        static let screenHeightDivider: CGFloat = 3
        static let titleCharacterDivider: Int = 18
        static let titleLineHeight: Int = 14
        static let authorCharacterDivider: Int = 20
        static let authorLineHeight: Int = 12
    }

    enum Gesture {
        static let minimumPressDuration: TimeInterval = 0.5
    }

    enum Animation {
        static let refreshDelayMilliseconds: Int = 500
        static let initialLoadDelayMilliseconds: Int = 300
    }
}