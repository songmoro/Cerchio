//
//  AppConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import Foundation

enum AppConstants {
    enum TabBar {
        enum Tags {
            static let library: Int = 0
            static let search: Int = 1
            static let settings: Int = 2
        }

        enum Titles {
            static let library = String(localized: .tabLibrary)
            static let search = String(localized: .tabSearch)
            static let settings = String(localized: .tabSettings)
        }

        enum SystemImages {
            static let library = SystemImage.library
            static let search = SystemImage.search
            static let settings = SystemImage.settings
        }
    }

    enum Navigation {
        enum Typography {
            static let titleFontSize: CGFloat = 17
        }
    }

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
