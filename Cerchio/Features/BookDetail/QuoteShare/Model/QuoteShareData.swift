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

    /// Blur intensity (0.0 - 1.0)
    var blurIntensity: CGFloat

    /// Default configuration
    static var `default`: QuoteBackgroundConfig {
        QuoteBackgroundConfig(
            isEnabled: false,
            blurIntensity: 0.5
        )
    }
}
