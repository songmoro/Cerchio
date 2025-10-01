//
//  AddPhotoCell.swift
//  Cerchio
//
//  Created by Claude Code on 10/1/25.
//

import UIKit
import SnapKit

final class AddPhotoCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "camera.fill"))
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = "추가"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()

    // MARK: - Properties
    var onAddPhotoTapped: (() -> Void)?

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
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(label)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-10)
            $0.width.height.equalTo(28)
        }

        label.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(iconImageView.snp.bottom).offset(4)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        onAddPhotoTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAddPhotoTapped = nil
    }
}
