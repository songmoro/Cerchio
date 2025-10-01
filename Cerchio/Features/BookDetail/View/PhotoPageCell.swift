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
    private let imageStackView = UIStackView()
    private let image1 = UIImageView()
    private let image2 = UIImageView()
    private let cameraButton = UIView()

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
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        contentView.addSubview(containerView)

        // 이미지 스택뷰 설정
        imageStackView.axis = .horizontal
        imageStackView.distribution = .fillEqually
        imageStackView.spacing = 8
        containerView.addSubview(imageStackView)

        // 이미지뷰 설정
        setupImageView(image1)
        setupImageView(image2)

        imageStackView.addArrangedSubview(image1)
        imageStackView.addArrangedSubview(image2)

        // 카메라 버튼 (3번째 위치)
        setupCameraButton()
        imageStackView.addArrangedSubview(cameraButton)
    }

    private func setupCameraButton() {
        cameraButton.backgroundColor = .systemGray6
        cameraButton.layer.cornerRadius = 8
        cameraButton.layer.borderWidth = 1
        cameraButton.layer.borderColor = UIColor.systemGray4.cgColor

        let iconImageView = UIImageView(image: UIImage(systemName: "camera.fill"))
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        cameraButton.addSubview(iconImageView)

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(32)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
        cameraButton.addGestureRecognizer(tapGesture)
        cameraButton.isUserInteractionEnabled = true
    }

    private func setupImageView(_ imageView: UIImageView) {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.systemGray4.cgColor
        imageView.isUserInteractionEnabled = true

        // 롱 프레스 제스처 추가
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        imageView.addGestureRecognizer(longPress)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        imageStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 전체 컨테이너의 높이를 너비의 1/3로 설정 (가로 1/3 크기가 정사각형이 되도록)
        containerView.snp.makeConstraints {
            $0.height.equalTo(containerView.snp.width).dividedBy(3)
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

        // 이미지가 없으면 카메라 버튼만 표시
        if images.isEmpty {
            image1.isHidden = true
            image2.isHidden = true
            cameraButton.isHidden = false
        } else {
            // 이미지가 있으면 최대 2개까지 표시
            let imageViews = [image1, image2]

            for (index, imageView) in imageViews.enumerated() {
                if index < images.count, let image = images[index] {
                    imageView.image = image
                    imageView.isHidden = false
                } else {
                    imageView.isHidden = true
                }
            }

            // 3번째는 카메라 버튼
            cameraButton.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        image1.image = nil
        image2.image = nil
        image1.isHidden = false
        image2.isHidden = false
        cameraButton.isHidden = false
        onAddPhotoTapped = nil
        onPhotoLongPressed = nil
        photos.removeAll()
    }
}