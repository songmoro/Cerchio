//
//  PhotoPageCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import SnapKit

final class PhotoPageCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let imageStackView = UIStackView()
    private let image1 = UIImageView()
    private let image2 = UIImageView()
    private let image3 = UIImageView()
    private let addButton = UIButton()

    // MARK: - Properties
    var onAddPhotoTapped: (() -> Void)?
    var onPhotoLongPressed: ((UIImageView, UIImage) -> Void)?
    private var photos: [UIImage] = []

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
        titleLabel.text = NSLocalizedString("book_detail.photos", comment: "Photos section title")
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        containerView.addSubview(titleLabel)

        // 이미지 스택뷰 설정
        imageStackView.axis = .horizontal
        imageStackView.distribution = .fillEqually
        imageStackView.spacing = 8
        containerView.addSubview(imageStackView)

        // 이미지뷰 설정
        setupImageView(image1)
        setupImageView(image2)
        setupImageView(image3)

        imageStackView.addArrangedSubview(image1)
        imageStackView.addArrangedSubview(image2)
        imageStackView.addArrangedSubview(image3)

        // 추가 버튼
        addButton.setTitle(NSLocalizedString("camera.capture_button", comment: "Take photo button"), for: .normal)
        addButton.setTitleColor(.systemBlue, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        addButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        containerView.addSubview(addButton)
    }

    private func setupImageView(_ imageView: UIImageView) {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.isUserInteractionEnabled = true

        // 플레이스홀더 이미지 설정
        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        imageView.image = placeholderImage

        // 롱 프레스 제스처 추가
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        imageView.addGestureRecognizer(longPress)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }

        titleLabel.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
        }

        imageStackView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(80)
        }

        addButton.snp.makeConstraints {
            $0.top.equalTo(imageStackView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(120)
            $0.height.equalTo(32)
            $0.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        onAddPhotoTapped?()
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let imageView = gesture.view as? UIImageView,
              let image = imageView.image,
              !isPlaceholderImage(image) else { return }

        onPhotoLongPressed?(imageView, image)
    }

    private func isPlaceholderImage(_ image: UIImage) -> Bool {
        // 플레이스홀더 이미지인지 확인
        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        return image.pngData() == placeholderImage?.pngData()
    }

    // MARK: - Configuration
    func configure(with images: [UIImage?]) {
        self.photos = images.compactMap { $0 }
        let imageViews = [image1, image2, image3]

        for (index, imageView) in imageViews.enumerated() {
            if index < images.count, let image = images[index] {
                imageView.image = image
            } else {
                // 플레이스홀더 이미지 설정
                let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
                imageView.image = placeholderImage
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 플레이스홀더 이미지로 리셋
        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray3, renderingMode: .alwaysOriginal)
        image1.image = placeholderImage
        image2.image = placeholderImage
        image3.image = placeholderImage
        onAddPhotoTapped = nil
        onPhotoLongPressed = nil
        photos.removeAll()
    }
}