//
//  AddQuoteButtonCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import SnapKit

final class AddQuoteButtonCell: UICollectionViewCell, IsIdentifiable {
    private let iconImageView = UIImageView()

    var onAddQuoteTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = .systemGray6
        contentView.layer.cornerRadius = 12

        iconImageView.image = UIImage(systemName: "plus.circle.fill")
        iconImageView.tintColor = .forestGreen
        iconImageView.contentMode = .scaleAspectFit
        contentView.addSubview(iconImageView)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(40)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(tapGesture)
    }

    @objc private func cellTapped() {
        onAddQuoteTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAddQuoteTapped = nil
    }
}
