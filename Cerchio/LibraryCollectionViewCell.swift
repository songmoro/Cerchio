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
        coverImageView.layer.cornerRadius = 8
        coverImageView.backgroundColor = .systemGray5
        contentView.addSubview(coverImageView)
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        
        authorLabel.font = .systemFont(ofSize: 12, weight: .regular)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = 0
        contentView.addSubview(authorLabel)
    }
    
    private func setupConstraints() {
        coverImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(coverImageView.snp.width).multipliedBy(4.0/3.0)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        
        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(4)
        }
    }
    
    private func getLabelHeight() -> CGFloat {
        fatalError("미사용")
//        return titleLabel.bounds.height + authorLabel.bounds.height
    }
    
    func configure(with item: Book) {
        titleLabel.text = item.title
        authorLabel.text = item.author
        
        guard let url = URL(string: item.image) else { return }
        coverImageView.kf.setImage(with: url)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
    }
}
