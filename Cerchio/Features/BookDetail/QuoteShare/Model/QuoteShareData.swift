//
//  QuoteShareData.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit

/// Data required to display and share a quote
struct QuoteShareData {
    /// Book cover image URL
    let bookCoverImageURL: String?

    /// Book cover image (if already loaded)
    let bookCoverImage: UIImage?

    /// Book title
    let bookTitle: String

    /// Book author
    let bookAuthor: String

    /// Quote text
    let quote: String

    /// Page number (optional)
    let pageNumber: Int?

    /// Date when quote was saved
    let date: Date

    /// Background image configuration
    var backgroundConfig: QuoteBackgroundConfig
}

/// Configuration for quote share background
struct QuoteBackgroundConfig: Equatable {
    /// Whether to show background image
    var isEnabled: Bool

    /// Whether blur effect is enabled
    var isBlurEnabled: Bool

    /// Blur intensity (0.0 - 1.0)
    var blurIntensity: CGFloat

    /// Whether blur color tint is enabled
    var isBlurColorEnabled: Bool

    /// Blur color tint
    var blurColor: UIColor

    /// Blur color opacity (0.0 - 1.0)
    var blurColorOpacity: CGFloat

    /// Whether opacity effect is enabled
    var isOpacityEnabled: Bool

    /// Image opacity (0.0 - 1.0)
    var imageOpacity: CGFloat

    /// Whether scale effect is enabled
    var isScaleEnabled: Bool

    /// Image scale (0.0 - 1.6, representing 0% - 160%)
    var imageScale: CGFloat

    /// Default configuration
    static var `default`: QuoteBackgroundConfig {
        QuoteBackgroundConfig(
            isEnabled: false,
            isBlurEnabled: true,
            blurIntensity: 0.5,
            isBlurColorEnabled: false,
            blurColor: .white,
            blurColorOpacity: 0.3,
            isOpacityEnabled: true,
            imageOpacity: 1.0,
            isScaleEnabled: true,
            imageScale: 1.0
        )
    }
}
