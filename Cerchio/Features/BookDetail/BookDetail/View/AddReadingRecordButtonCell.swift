//
//  AddReadingRecordButtonCell.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import SnapKit

final class AddReadingRecordButtonCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let iconImageView = UIImageView()

    // MARK: - Properties
    var onAddRecordTapped: (() -> Void)?

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

        // 아이콘 이미지뷰
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

    // MARK: - Actions
    @objc private func cellTapped() {
        onAddRecordTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAddRecordTapped = nil
    }
}
