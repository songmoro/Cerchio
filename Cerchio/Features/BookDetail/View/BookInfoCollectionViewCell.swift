//
//  BookInfoCollectionViewCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import SnapKit

final class BookInfoCollectionViewCell: UICollectionViewCell, IsIdentifiable {
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
        return label
    }()

    private let dateRangeLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: BookDetailConstants.Typography.dateRangeFontSize)
        label.textColor = .secondaryLabel
        return label
    }()

    private let tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = BookDetailConstants.Layout.stackSpacing
        stackView.alignment = .leading
        return stackView
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
        layer.cornerRadius = BookDetailConstants.Layout.cellCornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = BookDetailConstants.Shadow.offset
        layer.shadowRadius = BookDetailConstants.Shadow.radius
        layer.shadowOpacity = BookDetailConstants.Shadow.opacity

        contentView.addSubview(coverImageView)
        contentView.addSubview(infoStackView)

        // 정보 스택 뷰 구성
        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(authorLabel)
        infoStackView.addArrangedSubview(pagesLabel)
        infoStackView.addArrangedSubview(dateRangeLabel)
        infoStackView.addArrangedSubview(tagsStackView)

        setupConstraints()
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
    }

    // MARK: - Configuration
    func configure(with bookDetail: BookDetail) {
        titleLabel.text = bookDetail.book.title
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

        // 이미지 로드 (Kingfisher 사용 예정)
        // TODO: Kingfisher로 이미지 로드
        coverImageView.backgroundColor = .systemGray4
    }

    private func setupTags(_ tags: [String]) {
        // 기존 태그 제거
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // 새 태그 추가
        tags.forEach { tag in
            let tagLabel = createTagLabel(text: tag)
            tagsStackView.addArrangedSubview(tagLabel)
        }
    }

    private func createTagLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = "#\(text)"
        label.font = .custom(weight: .medium, size: BookDetailConstants.Typography.tagFontSize)
        label.textColor = .forestGreen
        label.backgroundColor = UIColor.forestGreen.withAlphaComponent(BookDetailConstants.Colors.tagBackgroundAlpha)
        label.layer.cornerRadius = BookDetailConstants.Layout.tagCornerRadius
        label.clipsToBounds = true
        label.textAlignment = .center

        // 패딩 추가
        label.snp.makeConstraints {
            $0.height.equalTo(BookDetailConstants.Layout.tagHeight)
        }

        return label
    }
}
