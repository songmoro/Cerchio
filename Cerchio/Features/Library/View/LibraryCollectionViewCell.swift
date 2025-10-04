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
        coverImageView.clipsToBounds = true
        coverImageView.backgroundColor = .bookBackground
        contentView.addSubview(coverImageView)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .bookBackground
        coverImageView.addSubview(loadingIndicator)

        titleLabel.font = .custom(weight: .semiBold, size: LibraryConstants.Typography.titleFontSize)
        titleLabel.numberOfLines = LibraryConstants.Typography.multilineLabel
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)

        authorLabel.font = .custom(weight: .regular, size: LibraryConstants.Typography.authorFontSize)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = LibraryConstants.Typography.multilineLabel
        contentView.addSubview(authorLabel)
    }
    
    private func setupConstraints() {
        coverImageView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
            $0.height.equalTo(coverImageView.snp.width).multipliedBy(LibraryConstants.Layout.aspectRatio)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(LibraryConstants.Layout.stackOffset)
            $0.leading.trailing.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(LibraryConstants.Layout.stackOffset)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(LibraryConstants.Layout.stackOffset)
        }
    }
    
    func configure(with item: Book, isLeftColumn: Bool) {
        self.isLeftColumn = isLeftColumn
        titleLabel.text = item.cleanTitle
        authorLabel.text = item.author

        // 컬럼에 따라 코너 반경 설정
        updateCornerRadius()

        guard let url = URL(string: item.image) else { return }

        // Kingfisher 로딩 인디케이터 설정
        loadingIndicator.startAnimating()

        coverImageView.kf.setImage(
            with: url,
            options: [
                .transition(.fade(0.2)),
                .cacheOriginalImage
            ]
        ) { [weak self] result in
            self?.loadingIndicator.stopAnimating()
        }
    }

    private func updateCornerRadius() {
        let cornerRadius: CGFloat = 12

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
