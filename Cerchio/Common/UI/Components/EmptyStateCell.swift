//
//  EmptyStateCell.swift
//  Cerchio
//
//  Created by 송재훈 on 10/18/25.
//

import UIKit
import SnapKit

final class EmptyStateCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let messageLabel = UILabel()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        contentView.backgroundColor = .clear

        messageLabel.font = .custom(weight: .regular, size: 15)
        messageLabel.textColor = .forestGreen.withAlphaComponent(0.6)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        contentView.addSubview(messageLabel)
    }

    private func setupConstraints() {
        // Set fixed height for empty state cells
        contentView.snp.makeConstraints {
            $0.height.equalTo(150)
        }

        messageLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }

    // MARK: - Configuration
    func configure(message: String) {
        messageLabel.text = message
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
    }
}
