//
//  LibraryCollectionViewCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/24/25.
//

import UIKit
import SnapKit
import Kingfisher

final class LibraryCollectionViewCell: UICollectionViewCell, IsIdentifiable {
    private let backgroundContainerView = UIView()
    private let coverImageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private var isLeftColumn = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundContainerView.layer.cornerRadius = LibraryConstants.Layout.backgroundCornerRadius
        backgroundContainerView.clipsToBounds = true
        contentView.addSubview(backgroundContainerView)

        coverImageView.contentMode = .scaleAspectFit
        coverImageView.clipsToBounds = true
        backgroundContainerView.addSubview(coverImageView)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemGray
        backgroundContainerView.addSubview(loadingIndicator)

        titleLabel.font = .custom(weight: .semiBold, size: LibraryConstants.Typography.titleFontSize)
        titleLabel.numberOfLines = LibraryConstants.Typography.multilineLabel
        titleLabel.textColor = .label
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(titleLabel)

        authorLabel.font = .custom(weight: .regular, size: LibraryConstants.Typography.authorFontSize)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = LibraryConstants.Typography.multilineLabel
        authorLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        authorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        contentView.addSubview(authorLabel)
    }
    
    private func setupConstraints() {
        backgroundContainerView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
            $0.height.equalTo(backgroundContainerView.snp.width)
        }

        coverImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backgroundContainerView.snp.bottom).offset(LibraryConstants.Layout.stackOffset + 4)
            $0.horizontalEdges.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(LibraryConstants.Layout.stackOffset)
            $0.horizontalEdges.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(LibraryConstants.Layout.stackOffset)
        }
    }
    
    func configure(with item: Book, isLeftColumn: Bool) {
        self.isLeftColumn = isLeftColumn
        titleLabel.text = item.cleanTitle
        authorLabel.text = item.author

        // 기본 배경색 설정
        backgroundContainerView.backgroundColor = .clear

        if let customCoverPath = item.customCoverImagePath,
           let customImage = ImageStorageManager.shared.loadImage(fromPath: customCoverPath) {
            coverImageView.image = customImage
            loadingIndicator.stopAnimating()

            // 커스텀 이미지의 주 색상 추출
            extractAndApplyDominantColor(from: customImage)
        } else if let url = URL(string: item.image) {
            loadingIndicator.startAnimating()

            coverImageView.kf.setImage(
                with: url,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            ) { [weak self] result in
                guard let self = self else { return }
                self.loadingIndicator.stopAnimating()

                // 다운로드된 이미지의 주 색상 추출
                if case .success(let imageResult) = result {
                    self.extractAndApplyDominantColor(from: imageResult.image)
                }
            }
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func extractAndApplyDominantColor(from image: UIImage) {
        Task {
            let dominantColor = await Task.detached(priority: .userInitiated) {
                DominantColorExtractor.extract(from: image).first ?? .gray
            }.value

            await MainActor.run {
                UIView.animate(withDuration: 0.3) {
                    self.backgroundContainerView.backgroundColor = dominantColor
                }
            }
        }
    }


    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        loadingIndicator.stopAnimating()

        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
    }
}
