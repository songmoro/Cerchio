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
    var onTagsTapped: (() -> Void)?
    var onReadingInfoTapped: (() -> Void)?

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let effectView = UIVisualEffectView(effect: blurEffect)
        return effectView
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(BookDetailConstants.Layout.overlayAlpha)
        return view
    }()

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = BookDetailConstants.Layout.coverImageCornerRadius
        imageView.backgroundColor = .systemGray5

        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = BookDetailConstants.Shadow.coverShadowOffset
        imageView.layer.shadowRadius = BookDetailConstants.Shadow.coverShadowRadius
        imageView.layer.shadowOpacity = BookDetailConstants.Shadow.coverShadowOpacity

        return imageView
    }()

    private let infoContainerView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .bold, size: BookDetailConstants.Typography.bookInfoTitleFontSize)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: BookDetailConstants.Typography.bookInfoSubtitleFontSize)
        label.textColor = UIColor.white.withAlphaComponent(BookDetailConstants.Typography.bookInfoSubtitleAlpha)
        label.numberOfLines = 1
        return label
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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.clipsToBounds = true

        contentView.addSubview(backgroundImageView)
        contentView.addSubview(blurEffectView)
        contentView.addSubview(overlayView)

        contentView.addSubview(coverImageView)

        contentView.addSubview(infoContainerView)

        tagsContainerView.addSubview(tagsStackView)

        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(authorLabel)
        infoStackView.addArrangedSubview(tagsContainerView)

        infoContainerView.addSubview(infoStackView)

        let tagsTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTagsTapped))
        tagsContainerView.addGestureRecognizer(tagsTapGesture)

        setupConstraints()
    }

    @objc private func handleTagsTapped() {
        onTagsTapped?()
    }

    private func setupConstraints() {
        let screenHeight = UIScreen.main.bounds.height
        let backgroundHeight = screenHeight / 2

        backgroundImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(backgroundHeight)
        }

        blurEffectView.snp.makeConstraints {
            $0.edges.equalTo(backgroundImageView)
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalTo(backgroundImageView)
        }

        coverImageView.snp.makeConstraints {
            $0.center.equalTo(backgroundImageView)
            $0.width.equalTo(BookDetailConstants.Layout.coverImageWidth)
            $0.height.equalTo(coverImageView.snp.width).dividedBy(BookDetailConstants.Layout.coverImageAspectRatio)
        }

        infoContainerView.snp.makeConstraints {
            $0.leading.equalTo(backgroundImageView).inset(BookDetailConstants.Layout.infoLeadingInset)
            $0.trailing.equalTo(backgroundImageView).inset(BookDetailConstants.Layout.infoLeadingInset)
            $0.bottom.equalTo(backgroundImageView).inset(BookDetailConstants.Layout.infoBottomInset)
        }

        infoStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tagsContainerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(BookDetailConstants.Layout.tagHeight)
        }

        tagsStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(with bookDetail: BookDetail) {
        titleLabel.text = bookDetail.book.cleanTitle
        authorLabel.text = bookDetail.book.author

        setupTags(bookDetail.tags)

        if let url = URL(string: bookDetail.book.image) {
            backgroundImageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )

            coverImageView.kf.setImage(
                with: url,
                placeholder: nil,
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            backgroundImageView.image = nil
            backgroundImageView.backgroundColor = .systemGray4
            coverImageView.image = nil
            coverImageView.backgroundColor = .systemGray4
        }
    }

    private func setupTags(_ tags: [String]) {
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if tags.isEmpty {
            let placeholderLabel = createPlaceholderLabel()
            tagsStackView.addArrangedSubview(placeholderLabel)
        } else {
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
        label.textColor = .white
        label.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        label.layer.cornerRadius = BookDetailConstants.Layout.tagCornerRadius
        label.clipsToBounds = true
        label.textAlignment = .center
        label.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        label.snp.makeConstraints {
            $0.height.equalTo(BookDetailConstants.Layout.tagHeight)
        }

        return label
    }

    private func createPlaceholderLabel() -> UILabel {
        let label = PaddingLabel()
        label.text = "+ 태그"
        label.font = .custom(weight: .medium, size: BookDetailConstants.Typography.tagFontSize)
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        label.layer.cornerRadius = BookDetailConstants.Layout.tagCornerRadius
        label.clipsToBounds = true
        label.textAlignment = .center
        label.padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        label.snp.makeConstraints {
            $0.height.equalTo(BookDetailConstants.Layout.tagHeight)
        }

        return label
    }
}

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
