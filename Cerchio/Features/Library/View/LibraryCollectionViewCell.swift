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
    private let coverImageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private var isLeftColumn = true

    // 이미지 높이 제약조건 (동적 업데이트용)
    private var imageHeightConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.layer.borderWidth = 2
        coverImageView.layer.borderColor = UIColor.bookBackground.cgColor
        coverImageView.clipsToBounds = true
        contentView.addSubview(coverImageView)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .bookBackground
        coverImageView.addSubview(loadingIndicator)

        titleLabel.font = .custom(weight: .semiBold, size: LibraryConstants.Typography.titleFontSize)
        titleLabel.numberOfLines = LibraryConstants.Typography.multilineLabel
        titleLabel.textColor = .label
        // 제목 레이블은 자신의 크기에 딱 맞게 (여백 없이)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        contentView.addSubview(titleLabel)

        authorLabel.font = .custom(weight: .regular, size: LibraryConstants.Typography.authorFontSize)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = LibraryConstants.Typography.multilineLabel
        // 작가 레이블은 아래쪽 여백이 늘어날 수 있도록
        authorLabel.setContentHuggingPriority(.defaultLow, for: .vertical)
        authorLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        contentView.addSubview(authorLabel)
    }
    
    private func setupConstraints() {
        coverImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
            // 높이는 이미지 로드 후 동적으로 설정
            imageHeightConstraint = $0.height.equalTo(100).constraint
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(LibraryConstants.Layout.stackOffset)
            $0.horizontalEdges.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(LibraryConstants.Layout.stackOffset)
            $0.horizontalEdges.equalTo(titleLabel)
            // bottom은 greaterThan으로 최소 여백 보장
            $0.bottom.lessThanOrEqualToSuperview().inset(LibraryConstants.Layout.stackOffset)
        }
    }
    
    func configure(with item: Book, isLeftColumn: Bool) {
        self.isLeftColumn = isLeftColumn
        titleLabel.text = item.cleanTitle
        authorLabel.text = item.author

        // 컬럼에 따라 코너 반경 설정
        updateCornerRadius()

        // Check for custom cover image first
        if let customCoverPath = item.customCoverImagePath,
           let customImage = ImageStorageManager.shared.loadImage(fromPath: customCoverPath) {
            // Use custom local cover image
            coverImageView.image = customImage
            loadingIndicator.stopAnimating()
            updateImageHeight(with: customImage)

            DispatchQueue.main.async { [weak self] in
                self?.validateLayout()
            }
        } else if let url = URL(string: item.image) {
            // Use original remote cover image
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

                // 이미지 로드 성공 시 실제 이미지 비율로 높이 업데이트
                switch result {
                case .success(let imageResult):
                    let image = imageResult.image
                    self.updateImageHeight(with: image)

                    // 레이아웃 검증 (레이블이 벗어났는지 확인)
                    DispatchQueue.main.async {
                        self.validateLayout()
                    }
                case .failure:
                    break
                }
            }
        } else {
            loadingIndicator.stopAnimating()
        }
    }

    private func validateLayout() {
        // 레이아웃이 완전히 적용될 때까지 대기
        layoutIfNeeded()

        // 셀 바운드
        let cellBounds = contentView.bounds

        // 저자 레이블이 셀을 벗어났는지 확인
        let authorFrame = authorLabel.frame
        let authorMaxY = authorFrame.maxY

        // 셀 높이보다 저자 레이블이 벗어난 경우
        if authorMaxY > cellBounds.height - LibraryConstants.Layout.stackOffset {
            print("[Cell Validation]  Author label overflow detected")
            print("  - Cell height: \(cellBounds.height)")
            print("  - Author maxY: \(authorMaxY)")

            // 컬렉션 뷰 레이아웃 무효화
            if let collectionView = superview as? UICollectionView {
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    private func updateImageHeight(with image: UIImage) {
        let imageAspectRatio = image.size.height / image.size.width

        // 현재 이미지 뷰의 너비 기준으로 높이 계산
        let imageViewWidth = coverImageView.bounds.width

        // 이미지 뷰 너비가 아직 설정되지 않았다면 레이아웃 후 재시도
        guard imageViewWidth > 0 else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateImageHeight(with: image)
            }
            return
        }

        let calculatedHeight = imageViewWidth * imageAspectRatio
        let currentHeight = coverImageView.bounds.height

        // 높이가 크게 달라진 경우만 업데이트 (5pt 이상 차이)
        guard abs(calculatedHeight - currentHeight) > 5 else { return }

        // 높이 제약조건 업데이트
        imageHeightConstraint?.update(offset: calculatedHeight)

        // 셀 레이아웃 즉시 업데이트
        setNeedsLayout()
        layoutIfNeeded()

        // 컬렉션 뷰에게 레이아웃 무효화 요청
        if let collectionView = superview as? UICollectionView {
            // 셀 크기가 변경되었으므로 레이아웃 무효화
            DispatchQueue.main.async {
                collectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }

    private func updateCornerRadius() {
        let cornerRadius: CGFloat = 16

        if isLeftColumn {
            // 왼쪽 셀: 왼쪽 모서리만 둥글게
            coverImageView.layer.cornerRadius = 0
            coverImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            coverImageView.layer.cornerRadius = cornerRadius
        } else {
            // 오른쪽 셀: 오른쪽 모서리만 둥글게
            coverImageView.layer.cornerRadius = 0
            coverImageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            coverImageView.layer.cornerRadius = cornerRadius
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.kf.cancelDownloadTask()
        coverImageView.image = nil
        loadingIndicator.stopAnimating()

        // Border 초기화
        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
    }
}
