//
//  QuoteShareData.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit

struct QuoteShareData {
    let bookCoverImageURL: String?

    let bookCoverImage: UIImage?

    let bookTitle: String

    let bookAuthor: String

    let quote: String

    let pageNumber: Int?

    let date: Date

    var backgroundConfig: QuoteBackgroundConfig
}

struct QuoteBackgroundConfig: Equatable {
    var isEnabled: Bool

    var isBlurEnabled: Bool

    var blurIntensity: CGFloat

    var isBlurColorEnabled: Bool

    var blurColor: UIColor

    var blurColorOpacity: CGFloat

    var isOpacityEnabled: Bool

    var imageOpacity: CGFloat

    var isScaleEnabled: Bool

    var imageScale: CGFloat

    var showBookInfo: Bool
    var showPageNumber: Bool
    var showDate: Bool

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
            imageScale: 1.0,
            showBookInfo: true,
            showPageNumber: true,
            showDate: true
        )
    }
}
