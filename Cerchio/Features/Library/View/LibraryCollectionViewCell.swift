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
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = LibraryConstants.Layout.cornerRadius
        coverImageView.backgroundColor = .systemGray5
        contentView.addSubview(coverImageView)
        
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
            $0.top.leading.trailing.equalToSuperview().inset(LibraryConstants.Layout.cellInset)
            $0.height.equalTo(coverImageView.snp.width).multipliedBy(LibraryConstants.Layout.aspectRatio)
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
    
    func configure(with item: RealmBook) {
        titleLabel.text = item.cleanTitle
        authorLabel.text = item.author

        guard let url = URL(string: item.image) else { return }
        coverImageView.kf.setImage(with: url)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
    }
}
