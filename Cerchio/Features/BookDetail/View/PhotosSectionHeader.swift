//
//  PhotosSectionHeader.swift
//  Cerchio
//
//  Created by Claude on 10/1/25.
//

import UIKit
import SnapKit

final class PhotosSectionHeader: UICollectionReusableView, IsIdentifiable {
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let viewAllButton = UIButton()

    // MARK: - Properties
    var onViewAllTapped: (() -> Void)?

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
        backgroundColor = .clear

        // 타이틀 레이블
        titleLabel.text = String(localized: .bookDetailPhotos)
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        // 전체 보기 버튼
        viewAllButton.setTitle(String(localized: .actionViewAll), for: .normal)
        viewAllButton.setTitleColor(.systemBlue, for: .normal)
        viewAllButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        viewAllButton.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
        addSubview(viewAllButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        viewAllButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Actions
    @objc private func viewAllButtonTapped() {
        onViewAllTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onViewAllTapped = nil
    }
}
