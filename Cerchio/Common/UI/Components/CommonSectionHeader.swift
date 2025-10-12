//
//  CommonSectionHeader.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import SnapKit

final class CommonSectionHeader: UICollectionReusableView, IsIdentifiable {
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let actionButton: UIButton = {
        var config = UIButton.Configuration.plain()
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
    var onActionTapped: (() -> Void)?

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

        titleLabel.font = .custom(weight: .bold, size: 20)
        titleLabel.textColor = .label
        addSubview(titleLabel)

        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        addSubview(actionButton)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        actionButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(title: String, actionTitle: String? = nil) {
        titleLabel.text = title

        if let actionTitle = actionTitle {
            actionButton.configuration?.title = actionTitle
            actionButton.isHidden = false
        } else {
            actionButton.isHidden = true
        }
    }

    // MARK: - Actions
    @objc private func actionButtonTapped() {
        onActionTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onActionTapped = nil
        actionButton.isHidden = true
    }
}
