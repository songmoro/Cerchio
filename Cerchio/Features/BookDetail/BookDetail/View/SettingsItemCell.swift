//
//  SettingsItemCell.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import SnapKit

final class SettingsItemCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 17)
        label.textColor = .label
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        return imageView
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

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
        backgroundColor = .systemBackground

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(chevronImageView)
        contentView.addSubview(separatorView)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
        }

        chevronImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(8)
            $0.height.equalTo(13)
        }

        separatorView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel)
            $0.trailing.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }

    // MARK: - Configuration
    func configure(icon: UIImage?, title: String) {
        iconImageView.image = icon
        titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
    }
}
