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
    private let quoteLabel = UILabel()
    private let pageLabel = UILabel()
    private let dateLabel = UILabel()

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

        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)

        // 문장 레이블
        quoteLabel.font = .systemFont(ofSize: 15, weight: .regular)
        quoteLabel.textColor = .label
        quoteLabel.numberOfLines = 0
        quoteLabel.textAlignment = .left
        containerView.addSubview(quoteLabel)

        // 페이지 레이블
        pageLabel.font = .systemFont(ofSize: 12, weight: .medium)
        pageLabel.textColor = .systemBlue
        containerView.addSubview(pageLabel)

        // 날짜 레이블
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        containerView.addSubview(dateLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        quoteLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        pageLabel.snp.makeConstraints {
            $0.top.equalTo(quoteLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview()
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(pageLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with quote: String, pageNumber: Int?, date: Date) {
        quoteLabel.text = "\"\(quote)\""

        if let pageNumber = pageNumber {
            pageLabel.text = "p.\(pageNumber)"
            pageLabel.isHidden = false
        } else {
            pageLabel.isHidden = true
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        dateLabel.text = formatter.string(from: date)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        quoteLabel.text = nil
        pageLabel.text = nil
        pageLabel.isHidden = false
        dateLabel.text = nil
    }
}