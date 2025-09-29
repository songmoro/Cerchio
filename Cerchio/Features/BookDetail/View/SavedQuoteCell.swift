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
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let quoteLabel = UILabel()
    private let dateLabel = UILabel()
    private let addButton = UIButton()

    // MARK: - Properties
    var onAddQuoteTapped: (() -> Void)?

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
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.systemGray5.cgColor

        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)

        // 타이틀 레이블
        titleLabel.text = NSLocalizedString("book_detail.saved_quotes", comment: "Saved quotes section title")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        containerView.addSubview(titleLabel)

        // 문장 레이블
        quoteLabel.text = NSLocalizedString("book_detail.no_quotes", comment: "No quotes message")
        quoteLabel.font = .systemFont(ofSize: 14, weight: .regular)
        quoteLabel.textColor = .secondaryLabel
        quoteLabel.numberOfLines = 3
        quoteLabel.textAlignment = .left
        containerView.addSubview(quoteLabel)

        // 날짜 레이블
        dateLabel.text = ""
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .tertiaryLabel
        containerView.addSubview(dateLabel)

        // 추가 버튼
        addButton.setTitle(NSLocalizedString("book_detail.add_quote", comment: "Add quote button"), for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        addButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        containerView.addSubview(addButton)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        quoteLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(quoteLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview()
        }

        addButton.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(120)
            $0.height.equalTo(32)
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        onAddQuoteTapped?()
    }

    // MARK: - Configuration
    func configure(with quote: String?, date: Date?) {
        if let quote = quote, !quote.isEmpty {
            quoteLabel.text = "\"\(quote)\""
            quoteLabel.textColor = .label

            if let date = date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                dateLabel.text = "저장일: \(formatter.string(from: date))"
            }
        } else {
            quoteLabel.text = NSLocalizedString("book_detail.no_quotes", comment: "No quotes message")
            quoteLabel.textColor = .secondaryLabel
            dateLabel.text = ""
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        quoteLabel.text = nil
        dateLabel.text = nil
        onAddQuoteTapped = nil
    }
}