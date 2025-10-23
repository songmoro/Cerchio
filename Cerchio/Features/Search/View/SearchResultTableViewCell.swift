//
//  SearchResultTableViewCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit
import SnapKit
import Kingfisher

final class SearchResultTableViewCell: UITableViewCell, IsIdentifiable {
    private let bookImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = SearchResultConstants.Layout.cornerRadius
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .bold, size: SearchResultConstants.Typography.titleFontSize)
        label.textColor = .label
        label.numberOfLines = SearchResultConstants.Typography.titleNumberOfLines
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: SearchResultConstants.Typography.authorFontSize)
        label.textColor = .secondaryLabel
        label.numberOfLines = SearchResultConstants.Typography.authorNumberOfLines
        return label
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(String(localized: .actionAdd), for: .normal)
        button.titleLabel?.font = .custom(weight: .medium, size: SearchResultConstants.Typography.buttonFontSize)
        button.backgroundColor = .forestGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = SearchResultConstants.Layout.cornerRadius
        return button
    }()

    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = SearchResultConstants.Layout.stackSpacing
        stackView.alignment = .leading
        return stackView
    }()

    private var addBookHandler: ((Book) -> Void)?
    private var currentBook: Book?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .systemBackground

        contentView.addSubview(bookImageView)
        contentView.addSubview(infoStackView)
        contentView.addSubview(addButton)

        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(authorLabel)

        setupConstraints()
        setupActions()
    }

    private func setupConstraints() {
        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(SearchResultConstants.Layout.cellHorizontalInset)
            $0.top.bottom.equalToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset)
            $0.width.equalTo(SearchResultConstants.Layout.imageWidth)
            $0.height.equalTo(SearchResultConstants.Layout.imageHeight)
        }

        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(SearchResultConstants.Layout.cellHorizontalInset)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(SearchResultConstants.Layout.buttonWidth)
            $0.height.equalTo(SearchResultConstants.Layout.buttonHeight)
        }

        infoStackView.snp.makeConstraints {
            $0.leading.equalTo(bookImageView.snp.trailing).offset(SearchResultConstants.Layout.contentSpacing)
            $0.trailing.equalTo(addButton.snp.leading).offset(-SearchResultConstants.Layout.contentSpacing)
            $0.centerY.equalToSuperview()
        }
    }

    private func setupActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
    }

    @objc private func addButtonTapped() {
        guard let book = currentBook else { return }
        HapticFeedbackManager.shared.impact()
        addBookHandler?(book)

        UIView.animate(withDuration: SearchResultConstants.Animation.buttonAnimationDuration, animations: {
            self.addButton.transform = CGAffineTransform(scaleX: SearchResultConstants.Animation.buttonScaleDown, y: SearchResultConstants.Animation.buttonScaleDown)
        }) { _ in
            UIView.animate(withDuration: SearchResultConstants.Animation.buttonAnimationDuration) {
                self.addButton.transform = .identity
            }
        }
    }

    func configure(with book: Book, addHandler: @escaping (Book) -> Void) {
        currentBook = book
        addBookHandler = addHandler

        titleLabel.text = book.title
        authorLabel.text = book.author

        if let imageURL = URL(string: book.image) {
            bookImageView.kf.setImage(
                with: imageURL,
                placeholder: UIImage(systemName: "book.fill"),
                options: [
                    .transition(.fade(0.3)),
                    .cacheOriginalImage
                ]
            )
        } else {
            bookImageView.image = UIImage(systemName: "book.fill")
            bookImageView.tintColor = .systemGray3
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.kf.cancelDownloadTask()
        bookImageView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
        currentBook = nil
        addBookHandler = nil
    }
}
