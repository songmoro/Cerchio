//
//  SavedQuotesSectionHeader.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import SnapKit

final class SavedQuotesSectionHeader: UICollectionReusableView, IsIdentifiable {
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let editButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: .actionViewAll)
        config.baseForegroundColor = .systemBlue
        config.contentInsets = .zero

        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .custom(weight: .medium, size: 16)
                return outgoing
            }
            button.configuration = config
        }
        return button
    }()

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
        titleLabel.text = String(localized: .bookDetailSavedQuotes)
        titleLabel.font = .custom(weight: .bold, size: 20)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        // 전체 보기 버튼
        editButton.addTarget(self, action: #selector(viewAllButtonTapped), for: .touchUpInside)
        addSubview(editButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        editButton.snp.makeConstraints {
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
