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
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: SearchResultConstants.Typography.authorFontSize)
        label.textColor = .secondaryLabel
        label.numberOfLines = SearchResultConstants.Typography.authorNumberOfLines
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: SearchResultConstants.Typography.descriptionFontSize)
        label.textColor = .label
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
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

    private let expandButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: SearchResultConstants.Typography.expandButtonSize, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        button.tintColor = .secondaryLabel
        return button
    }()

    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = SearchResultConstants.Layout.stackSpacing
        stackView.alignment = .leading
        return stackView
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = SearchResultConstants.Layout.buttonStackSpacing
        stackView.alignment = .trailing
        return stackView
    }()

    private var addBookHandler: ((Book) -> Void)?
    private var onExpandToggled: (() -> Void)?
    private var currentBook: Book?
    private var isExpanded: Bool = false

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
        contentView.addSubview(buttonStackView)

        infoStackView.addArrangedSubview(titleLabel)
        infoStackView.addArrangedSubview(authorLabel)
        infoStackView.addArrangedSubview(descriptionLabel)

        buttonStackView.addArrangedSubview(addButton)
        buttonStackView.addArrangedSubview(expandButton)

        setupConstraints()
        setupActions()
    }

    private func setupConstraints() {
        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(SearchResultConstants.Layout.cellHorizontalInset)
            $0.top.equalToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset)
            $0.width.equalTo(SearchResultConstants.Layout.imageWidth)
            $0.height.equalTo(SearchResultConstants.Layout.imageHeight)
            $0.bottom.lessThanOrEqualToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset).priority(.high)
        }

        addButton.snp.makeConstraints {
            $0.width.equalTo(SearchResultConstants.Layout.buttonWidth)
            $0.height.equalTo(SearchResultConstants.Layout.buttonHeight)
        }

        expandButton.snp.makeConstraints {
            $0.width.height.equalTo(SearchResultConstants.Layout.expandButtonSize)
        }

        buttonStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(SearchResultConstants.Layout.cellHorizontalInset)
            $0.top.equalToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset)
        }

        infoStackView.snp.makeConstraints {
            $0.leading.equalTo(bookImageView.snp.trailing).offset(SearchResultConstants.Layout.contentSpacing)
            $0.trailing.equalTo(buttonStackView.snp.leading).offset(-SearchResultConstants.Layout.contentSpacing)
            $0.top.equalToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset).priority(.required)
            $0.bottom.equalToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset).priority(.high)
        }
    }

    private func setupActions() {
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        expandButton.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
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

    @objc private func expandButtonTapped() {
        HapticFeedbackManager.shared.selection()

        isExpanded.toggle()
        authorLabel.numberOfLines = isExpanded ? 2 : 1
        descriptionLabel.numberOfLines = isExpanded ? 0 : 1

        let config = UIImage.SymbolConfiguration(pointSize: SearchResultConstants.Typography.expandButtonSize, weight: .medium)
        let imageName = isExpanded ? "chevron.down" : "chevron.right"
        expandButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)

        onExpandToggled?()
    }

    func configure(with book: Book, addHandler: @escaping (Book) -> Void, onExpandToggled: @escaping () -> Void) {
        currentBook = book
        addBookHandler = addHandler
        self.onExpandToggled = onExpandToggled

        titleLabel.text = book.title
        authorLabel.text = book.author.replacingOccurrences(of: "^", with: ", ")
        descriptionLabel.text = book.cleanDescription.isEmpty ? book.bookDescription : book.cleanDescription

        expandButton.isHidden = descriptionLabel.text?.isEmpty ?? true

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
        authorLabel.numberOfLines = 1
        descriptionLabel.text = nil
        descriptionLabel.numberOfLines = 1
        isExpanded = false
        expandButton.isHidden = false

        let config = UIImage.SymbolConfiguration(pointSize: SearchResultConstants.Typography.expandButtonSize, weight: .medium)
        expandButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)

        currentBook = nil
        addBookHandler = nil
        onExpandToggled = nil
    }
}
