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
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var gridStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    // MARK: - Properties
    var onAddPhotoTapped: (() -> Void)?
    var onPhotoTapped: ((UIImage) -> Void)?
    var onPhotoLongPressed: ((UIImageView, UIImage) -> Void)?
    private var photoImageViews: [UIImageView] = []
    private var addPhotoButton: UIView?

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
        containerView.addSubview(gridStackView)

        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
        }

        gridStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(gridStackView.snp.width).dividedBy(3)
        }
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        onAddPhotoTapped?()
    }

    @objc private func photoTapped(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView,
              let image = imageView.image else { return }
        onPhotoTapped?(image)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let imageView = gesture.view as? UIImageView,
              let image = imageView.image else { return }

        onPhotoLongPressed?(imageView, image)
    }

    // MARK: - Configuration
    func configure(with images: [UIImage]) {
        // 기존 뷰 제거
        gridStackView.arrangedSubviews.forEach {
            gridStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        photoImageViews.removeAll()
        addPhotoButton = nil

        // 사진이 없으면 추가 버튼만 표시 (1x1 그리드)
        if images.isEmpty {
            let button = createAddPhotoButton()
            gridStackView.addArrangedSubview(button)
            addPhotoButton = button
        } else {
            // 최대 3개 사진을 3열로 표시
            let photoCount = min(images.count, 3)

            for i in 0..<3 {
                if i < photoCount {
                    // 사진 표시
                    let imageView = createPhotoImageView(with: images[i])
                    gridStackView.addArrangedSubview(imageView)
                    photoImageViews.append(imageView)
                } else {
                    // 빈 공간에 추가 버튼 (첫 번째 빈 공간에만)
                    if addPhotoButton == nil {
                        let button = createAddPhotoButton()
                        gridStackView.addArrangedSubview(button)
                        addPhotoButton = button
                    } else {
                        // 나머지 빈 공간
                        let placeholder = createPlaceholderView()
                        gridStackView.addArrangedSubview(placeholder)
                    }
                }
            }
        }
    }

    private func createPhotoImageView(with image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.systemGray5.cgColor
        imageView.isUserInteractionEnabled = true

        // 탭 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(photoTapped(_:)))
        imageView.addGestureRecognizer(tapGesture)

        // 롱 프레스 제스처
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        imageView.addGestureRecognizer(longPress)

        return imageView
    }

    private func createAddPhotoButton() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.systemGray4.withAlphaComponent(0.5).cgColor

        let iconImageView = UIImageView(image: UIImage(systemName: "camera.fill"))
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        view.addSubview(iconImageView)

        iconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(24)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
        view.addGestureRecognizer(tapGesture)
        view.isUserInteractionEnabled = true

        return view
    }

    private func createPlaceholderView() -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        gridStackView.arrangedSubviews.forEach {
            gridStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        photoImageViews.removeAll()
        addPhotoButton = nil
        onAddPhotoTapped = nil
        onPhotoTapped = nil
        onPhotoLongPressed = nil
    }
}
