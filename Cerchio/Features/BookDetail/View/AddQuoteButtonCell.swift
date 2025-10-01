//
//  AddQuoteButtonCell.swift
//  Cerchio
//
//  Created by Claude on 9/30/25.
//

import UIKit
import SnapKit

final class AddQuoteButtonCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()

    // MARK: - Properties
    var onAddQuoteTapped: (() -> Void)?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupViews() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12

        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)

        // 아이콘 이미지뷰
        iconImageView.image = UIImage(systemName: "plus.circle.fill")
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        containerView.addSubview(iconImageView)

        // 타이틀 레이블
        titleLabel.text = String(localized: .bookDetailAddQuote)
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .systemBlue
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        iconImageView.snp.makeConstraints {
            $0.top.centerX.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(8)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions
    @objc private func cellTapped() {
        onAddQuoteTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAddQuoteTapped = nil
    }
}
