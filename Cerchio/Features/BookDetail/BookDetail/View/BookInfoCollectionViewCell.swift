//
//  BookInfoCollectionViewCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import SnapKit
import Kingfisher

final class BookInfoCollectionViewCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - Callback
    var onTagsTapped: (() -> Void)?
    var onReadingInfoTapped: (() -> Void)?

    // MARK: - UI Components
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = BookDetailConstants.Layout.imageCornerRadius
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .bold, size: BookDetailConstants.Typography.titleFontSize)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: BookDetailConstants.Typography.authorFontSize)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let pagesLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: BookDetailConstants.Typography.pagesFontSize)
        label.textColor = .secondaryLabel
        label.isUserInteractionEnabled = true
        return label
    }()

    private let dateRangeLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: BookDetailConstants.Typography.dateRangeFontSize)
        label.textColor = .secondaryLabel
        label.isUserInteractionEnabled = true
        return label
    }()

    private let readingInfoContainer: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()

    private let tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = BookDetailConstants.Layout.stackSpacing
        stackView.alignment = .leading
        return stackView
    }()

    private let tagsContainerView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()

    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = BookDetailConstants.Layout.stackSpacing
        stackView.alignment = .leading
        return stackView
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemBackground

        contentView.addSubview(coverImageView)
        contentView.addSubview(infoStackView)

        // 태그 컨테이너 설정
        tagsContainerView.addSubview(tagsStackView)

        // 독서 정보 컨테이너 설정
        readingInfoContainer.addSubview(pagesLabel)
        readingInfoContainer.addSubview(dateRangeLabel)

        // 정보 스택 뷰 구성
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(authorLabel)
        infoStackView.addArrangedSubview(readingInfoContainer)
        infoStackView.addArrangedSubview(tagsContainerView)

        // 태그 컨테이너 탭 제스처 추가
        let tagsTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTagsTapped))
        tagsContainerView.addGestureRecognizer(tagsTapGesture)

        // 독서 정보 탭 제스처 추가
        let readingInfoTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleReadingInfoTapped))
        readingInfoContainer.addGestureRecognizer(readingInfoTapGesture)

        setupConstraints()
    }

    @objc private func handleTagsTapped() {
        onTagsTapped?()
    }

    @objc private func handleReadingInfoTapped() {
        onReadingInfoTapped?()
    }

    private func setupConstraints() {
        // 커버 이미지 (왼쪽 1/3)
        coverImageView.snp.makeConstraints {
            $0.leading.top.bottom.equalToSuperview().inset(BookDetailConstants.Layout.cellInset)
            $0.width.equalToSuperview().multipliedBy(BookDetailConstants.Layout.coverWidthMultiplier)
            $0.height.equalTo(coverImageView.snp.width).multipliedBy(BookDetailConstants.Layout.aspectRatio)
        }

        // 정보 스택 뷰 (오른쪽 2/3)
        infoStackView.snp.makeConstraints {
            $0.leading.equalTo(coverImageView.snp.trailing).offset(BookDetailConstants.Layout.cellInset)
            $0.trailing.equalToSuperview().inset(BookDetailConstants.Layout.cellInset)
            $0.top.equalToSuperview().inset(BookDetailConstants.Layout.cellInset)
            $0.bottom.lessThanOrEqualToSuperview().inset(BookDetailConstants.Layout.cellInset)
        }

        // 독서 정보 컨테이너
        readingInfoContainer.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(44)
        }

        pagesLabel.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
        }

        dateRangeLabel.snp.makeConstraints {
            $0.top.equalTo(pagesLabel.snp.bottom).offset(4)
            $0.horizontalEdges.bottom.equalToSuperview()
        }

        // 태그 컨테이너
        tagsContainerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(BookDetailConstants.Layout.tagHeight)
        }

        // 태그 스택 뷰
        tagsStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with bookDetail: BookDetail) {
        titleLabel.text = bookDetail.book.cleanTitle
        authorLabel.text = bookDetail.book.author
        pagesLabel.text = "\(bookDetail.totalPages)페이지"

        // 독서 기간 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd"

        if let startDate = bookDetail.startDate {
            let startDateString = dateFormatter.string(from: startDate)
            if let endDate = bookDetail.endDate {
                let endDateString = dateFormatter.string(from: endDate)
                dateRangeLabel.text = "\(startDateString) ~ \(endDateString)"
            } else {
                dateRangeLabel.text = "\(startDateString) ~ 읽는 중"
            }
        } else {
            dateRangeLabel.text = "독서 시작 전"
        }

        // 태그 설정
        setupTags(bookDetail.tags)

        // 이미지 로드
        if let url = URL(string: bookDetail.book.image) {
            coverImageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        } else {
            coverImageView.image = nil
            coverImageView.backgroundColor = .systemGray4
        }
    }

    private func setupTags(_ tags: [String]) {
        // 기존 태그 제거
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if tags.isEmpty {
            // 태그가 없을 때 플레이스홀더 표시
            let placeholderLabel = createPlaceholderLabel()
            tagsStackView.addArrangedSubview(placeholderLabel)
        } else {
            // 새 태그 추가
            tags.forEach { tag in
                let tagLabel = createTagLabel(text: tag)
                tagsStackView.addArrangedSubview(tagLabel)
            }
        }
    }

    private func createTagLabel(text: String) -> UILabel {
        let label = PaddingLabel()
        label.text = "#\(text)"
        label.font = .custom(weight: .medium, size: BookDetailConstants.Typography.tagFontSize)
        label.textColor = .forestGreen
        label.backgroundColor = UIColor.forestGreen.withAlphaComponent(BookDetailConstants.Colors.tagBackgroundAlpha)
        label.layer.cornerRadius = BookDetailConstants.Layout.tagCornerRadius
        label.clipsToBounds = true
        label.textAlignment = .center
        label.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        // 높이 제약
        label.snp.makeConstraints {
            $0.height.equalTo(BookDetailConstants.Layout.tagHeight)
        }

        return label
    }

    private func createPlaceholderLabel() -> UILabel {
        let label = PaddingLabel()
        label.text = "+ 태그"
        label.font = .custom(weight: .medium, size: BookDetailConstants.Typography.tagFontSize)
        label.textColor = .secondaryLabel
        label.backgroundColor = UIColor.systemGray6
        label.layer.cornerRadius = BookDetailConstants.Layout.tagCornerRadius
        label.clipsToBounds = true
        label.textAlignment = .center
        label.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        // 높이 제약
        label.snp.makeConstraints {
            $0.height.equalTo(BookDetailConstants.Layout.tagHeight)
        }

        return label
    }
}

// MARK: - PaddingLabel
private class PaddingLabel: UILabel {
    var padding = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += padding.left + padding.right
        contentSize.height += padding.top + padding.bottom
        return contentSize
    }
}
