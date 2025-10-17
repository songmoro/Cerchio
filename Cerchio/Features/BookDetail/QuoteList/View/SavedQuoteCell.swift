//
//  SavedQuoteCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import SnapKit

final class SavedQuoteCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        contentView.backgroundColor = .clear
    }

    // MARK: - Configuration
    func configure(with quote: String, pageNumber: Int?, date: Date) {
        var config = UIListContentConfiguration.subtitleCell()

        // 문장 텍스트
        config.text = "\"\(quote)\""
        config.textProperties.font = .custom(weight: .regular, size: 15)
        config.textProperties.color = .label
        config.textProperties.numberOfLines = 0

        // 페이지 정보와 날짜를 secondary text로 표시
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let dateString = formatter.string(from: date)

        if let pageNumber = pageNumber {
            config.secondaryText = "p.\(pageNumber) · \(dateString)"
            config.secondaryTextProperties.font = .custom(weight: .medium, size: 12)
            config.secondaryTextProperties.color = .forestGreen
        } else {
            config.secondaryText = dateString
            config.secondaryTextProperties.font = .custom(weight: .regular, size: 12)
            config.secondaryTextProperties.color = .forestGreen
        }

        config.directionalLayoutMargins = .zero

        contentConfiguration = config
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
    }
}
