//
//  PhotoItemCell.swift
//  Cerchio
//
//  Created by Claude Code on 10/1/25.
//

import UIKit
import SnapKit

final class PhotoItemCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    // MARK: - Properties
    var onPhotoTapped: ((UIImage) -> Void)?

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
        contentView.addSubview(imageView)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 탭 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped))
        imageView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions
    @objc private func photoTapped() {
        guard let image = imageView.image else { return }
        onPhotoTapped?(image)
    }

    // MARK: - Configuration
    func configure(with image: UIImage?) {
        imageView.image = image
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        onPhotoTapped = nil
    }
}
