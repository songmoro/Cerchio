//
//  AddActionCell.swift
//  Cerchio
//
//  Created by 송재훈 on 10/20/25.
//

import UIKit
import SnapKit
import RxSwift

final class AddActionCell: UICollectionViewCell, IsIdentifiable {
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let containerView = UIView()

    var onTapped: (() -> Void)?

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
        contentView.backgroundColor = .clear

        containerView.backgroundColor = .clear
        containerView.layer.borderColor = UIColor.forestGreen.withAlphaComponent(0.3).cgColor
        containerView.layer.borderWidth = 1.5
        containerView.layer.cornerRadius = 12

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .forestGreen

        titleLabel.font = .custom(weight: .medium, size: 16)
        titleLabel.textColor = .forestGreen
        titleLabel.textAlignment = .center

        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(56)
            $0.leading.trailing.equalToSuperview().inset(40)
        }

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }

    @objc private func handleTap() {
        HapticFeedbackManager.shared.impact()

        UIView.animate(withDuration: 0.1, animations: {
            self.containerView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.containerView.transform = .identity
            }
        }

        onTapped?()
    }

    func configure(icon: UIImage?, title: String, action: @escaping () -> Void) {
        iconImageView.image = icon
        titleLabel.text = title
        onTapped = action
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
        titleLabel.text = nil
        onTapped = nil
    }
}
