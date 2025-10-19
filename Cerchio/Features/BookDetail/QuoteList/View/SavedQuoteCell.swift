//
//  SavedQuoteCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import SnapKit

final class SavedQuoteCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let headerContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let metadataStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 13)
        label.textColor = .forestGreen
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 11)
        label.textColor = .secondaryLabel
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        config.baseForegroundColor = .secondaryLabel
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        button.configuration = config
        return button
    }()

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 15)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Properties
    var onActionButtonTapped: (() -> Void)?

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

        contentView.addSubview(headerContainer)
        headerContainer.addSubview(metadataStack)
        headerContainer.addSubview(actionButton)
        contentView.addSubview(quoteLabel)

        metadataStack.addArrangedSubview(pageLabel)
        metadataStack.addArrangedSubview(dateLabel)

        headerContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.leading.equalToSuperview() //.offset(16)
            $0.trailing.equalToSuperview() //.offset(-16)
        }

        metadataStack.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        actionButton.snp.makeConstraints {
            $0.centerY.equalTo(metadataStack)
            $0.trailing.equalToSuperview()
            $0.leading.greaterThanOrEqualTo(metadataStack.snp.trailing).offset(8)
        }

        quoteLabel.snp.makeConstraints {
            $0.top.equalTo(headerContainer.snp.bottom).offset(8)
            $0.leading.equalToSuperview() //.offset(16)
            $0.trailing.equalToSuperview() //.offset(-16)
            $0.bottom.equalToSuperview().offset(-12)
        }

        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func actionButtonTapped() {
        HapticFeedbackManager.shared.impact()
        onActionButtonTapped?()
    }

    // MARK: - Configuration
    func configure(with quote: String, pageNumber: Int?, date: Date) {
        // 페이지 번호
        if let pageNumber = pageNumber {
            pageLabel.text = "p.\(pageNumber)"
            pageLabel.isHidden = false
        } else {
            pageLabel.isHidden = true
        }

        // 문장 텍스트
        quoteLabel.text = "\"\(quote)\""

        // 날짜
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        dateLabel.text = formatter.string(from: date)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        pageLabel.text = nil
        pageLabel.isHidden = false
        quoteLabel.text = nil
        dateLabel.text = nil
        onActionButtonTapped = nil
    }
}
