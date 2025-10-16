//
//  BookInfoHeaderView.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import SnapKit
import Kingfisher

final class BookInfoHeaderView: UICollectionReusableView, IsIdentifiable {
    // MARK: - Callback
    var onTagsTapped: (() -> Void)?
    var onReadingInfoTapped: (() -> Void)?

    // MARK: - UI Components

    // Background layers
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
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = BookDetailConstants.Layout.coverImageCornerRadius
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
        label.textColor = .bookBackground
        label.numberOfLines = 2
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: BookDetailConstants.Typography.bookInfoSubtitleFontSize)
        label.textColor = .bookBackground
        label.numberOfLines = 1
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = BookDetailConstants.Layout.stackSpacing
        stackView.alignment = .leading
        return stackView
    }()

    private let tagsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
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
        stackView.distribution = .fill
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
        clipsToBounds = true

        addSubview(backgroundImageView)
        addSubview(blurEffectView)
        addSubview(overlayView)
        addSubview(coverImageView)
        addSubview(infoContainerView)

        tagsScrollView.addSubview(tagsStackView)
        tagsContainerView.addSubview(tagsScrollView)

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
        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints {
            $0.edges.equalTo(backgroundImageView)
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalTo(backgroundImageView)
        }
        
        let coverImageWidth = BookDetailConstants.Layout.coverImageWidth * 1.2
        coverImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview(\.safeAreaLayoutGuide)
            $0.width.equalTo(coverImageWidth)
            $0.height.equalTo(coverImageView.snp.width).dividedBy(BookDetailConstants.Layout.coverImageAspectRatio)
        }

        infoContainerView.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(BookDetailConstants.Layout.infoLeadingInset)
            $0.trailing.equalToSuperview().inset(BookDetailConstants.Layout.infoLeadingInset)
            $0.bottom.lessThanOrEqualToSuperview().inset(BookDetailConstants.Layout.infoBottomInset)
        }
        
        infoStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tagsContainerView.snp.makeConstraints {
            $0.height.equalTo(BookDetailConstants.Layout.tagHeight)
            $0.leading.trailing.equalToSuperview()
        }

        tagsScrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        tagsStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalToSuperview()
        }
    }

    // MARK: - Configuration
    func configure(with bookDetail: BookDetail) {
        titleLabel.text = bookDetail.book.customTitle ?? bookDetail.book.cleanTitle
        authorLabel.text = bookDetail.book.author

        titleLabel.textColor = .bookBackground
        authorLabel.textColor = .bookBackground

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

            // Override colors for dark background
            titleLabel.textColor = .white
            authorLabel.textColor = UIColor.white.withAlphaComponent(BookDetailConstants.Typography.bookInfoSubtitleAlpha)
        }
    }

    private func setupTags(_ tags: [String]) {
        tagsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        tags.forEach { tag in
            let tagLabel = createTagLabel(text: tag)
            tagsStackView.addArrangedSubview(tagLabel)
        }
        
        let placeholderLabel = createPlaceholderLabel()
        tagsStackView.addArrangedSubview(placeholderLabel)
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

// MARK: - UIImage Extension for Brightness
extension UIImage {
    func averageBrightness() -> CGFloat {
        guard let inputImage = CIImage(image: self) else { return 0.5 }

        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: inputImage,
                                               kCIInputExtentKey: extentVector]) else { return 0.5 }
        guard let outputImage = filter.outputImage else { return 0.5 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        // Calculate brightness (weighted average of RGB)
        let brightness = (0.299 * CGFloat(bitmap[0]) + 0.587 * CGFloat(bitmap[1]) + 0.114 * CGFloat(bitmap[2])) / 255.0

        return brightness
    }
}
