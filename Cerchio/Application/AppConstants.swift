//
//  AppConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

enum AppConstants {

    // MARK: - TabBar
    enum TabBar {
        enum Tags {
            static let library: Int = 0
            static let search: Int = 1
            static let settings: Int = 2
        }

        enum Typography {
            static let placeholderFontSize: CGFloat = 18
        }

        enum Titles {
            static let library = "서재"
            static let search = "검색"
            static let settings = "설정"
            static let placeholder = "준비 중"
        }

        enum SystemImages {
            static let library = "books.vertical"
            static let search = "magnifyingglass"
            static let settings = "gearshape"
        }
    }

    // MARK: - Navigation
    enum Navigation {
        enum Typography {
            static let titleFontSize: CGFloat = 17
        }
    }

    // MARK: - General
    enum General {
        enum Layout {
            static let standardCornerRadius: CGFloat = 8
            static let standardInset: CGFloat = 16
            static let smallInset: CGFloat = 8
            static let largeInset: CGFloat = 24
        }

        enum Typography {
            static let titleFontSize: CGFloat = 17
            static let bodyFontSize: CGFloat = 15
            static let captionFontSize: CGFloat = 12
            static let smallFontSize: CGFloat = 14
            static let largeFontSize: CGFloat = 20
        }

        enum Animation {
            static let defaultDuration: Double = 0.25
            static let fastDuration: Double = 0.15
            static let slowDuration: Double = 0.35
        }
    }
}