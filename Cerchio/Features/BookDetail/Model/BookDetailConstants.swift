//
//  BookDetailConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit

enum BookDetailConstants {

    // MARK: - Layout
    enum Layout {
        static let estimatedHeight: CGFloat = 400
        static let sectionContentInsets = NSDirectionalEdgeInsets(
            top: 16,
            leading: 16,
            bottom: 16,
            trailing: 16
        )
        static let cellCornerRadius: CGFloat = 12
        static let imageCornerRadius: CGFloat = 8
        static let tagCornerRadius: CGFloat = 8
        static let cellInset: CGFloat = 16
        static let stackSpacing: CGFloat = 8
        static let tagHeight: CGFloat = 24
        static let coverWidthMultiplier: CGFloat = 0.3
        static let aspectRatio: CGFloat = 4.0/3.0

        // New BookInfo cell design
        static let bookInfoCellHeight: CGFloat = 500
        static let backgroundImageHeightMultiplier: CGFloat = 0.5 // Half screen
        static let coverImageWidth: CGFloat = 120
        static let coverImageAspectRatio: CGFloat = 3.0 / 4.0 // 3:4 ratio
        static let coverImageCornerRadius: CGFloat = 8
        static let overlayAlpha: CGFloat = 0.1
        static let infoBottomInset: CGFloat = 16
        static let infoLeadingInset: CGFloat = 16
    }

    // MARK: - Typography
    enum Typography {
        static let titleFontSize: CGFloat = 18
        static let authorFontSize: CGFloat = 14
        static let pagesFontSize: CGFloat = 14
        static let dateRangeFontSize: CGFloat = 14
        static let tagFontSize: CGFloat = 12

        // New BookInfo cell typography
        static let bookInfoTitleFontSize: CGFloat = 18
        static let bookInfoSubtitleFontSize: CGFloat = 16
        static let bookInfoSubtitleAlpha: CGFloat = 0.8
    }

    // MARK: - Shadow
    enum Shadow {
        static let offset = CGSize(width: 0, height: 2)
        static let radius: CGFloat = 4
        static let opacity: Float = 0.1

        // Cover image shadow
        static let coverShadowOffset = CGSize(width: 0, height: 8)
        static let coverShadowRadius: CGFloat = 16
        static let coverShadowOpacity: Float = 0.3
    }

    // MARK: - Colors
    enum Colors {
        static let tagBackgroundAlpha: CGFloat = 0.1
    }
}
