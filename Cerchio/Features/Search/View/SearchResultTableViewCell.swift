//
//  SearchResultTableViewCell.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit
import SnapKit

final class SearchResultTableViewCell: UITableViewCell {
    static let identifier = "SearchResultTableViewCell"

    // MARK: - UI Components
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
        label.numberOfLines = 2
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: SearchResultConstants.Typography.authorFontSize)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("담기", for: .normal)
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

    // MARK: - Properties
    private var addBookHandler: ((Book) -> Void)?
    private var currentBook: Book?

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
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
        // 이미지 뷰 (가로 너비의 1/4 정도)
        bookImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(SearchResultConstants.Layout.cellHorizontalInset)
            $0.top.bottom.equalToSuperview().inset(SearchResultConstants.Layout.cellVerticalInset)
            $0.width.equalTo(SearchResultConstants.Layout.imageWidth) // 고정 크기
            $0.height.equalTo(SearchResultConstants.Layout.imageHeight) // 4:3 비율보다 세로로 긴 책 모양
        }

        // 담기 버튼 (세로 중심)
        addButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(SearchResultConstants.Layout.cellHorizontalInset)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(SearchResultConstants.Layout.buttonWidth)
            $0.height.equalTo(SearchResultConstants.Layout.buttonHeight)
        }

        // 정보 스택뷰 (이미지와 버튼 사이)
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
        addBookHandler?(book)

        // 버튼 애니메이션
        UIView.animate(withDuration: SearchResultConstants.Animation.buttonAnimationDuration, animations: {
            self.addButton.transform = CGAffineTransform(scaleX: SearchResultConstants.Animation.buttonScaleDown, y: SearchResultConstants.Animation.buttonScaleDown)
        }) { _ in
            UIView.animate(withDuration: SearchResultConstants.Animation.buttonAnimationDuration) {
                self.addButton.transform = .identity
            }
        }
    }

    // MARK: - Configuration
    func configure(with book: Book, addHandler: @escaping (Book) -> Void) {
        currentBook = book
        addBookHandler = addHandler

        titleLabel.text = book.title
        authorLabel.text = book.author

        // TODO: Kingfisher로 이미지 로드
        // bookImageView.kf.setImage(with: URL(string: book.image))
        bookImageView.backgroundColor = .systemGray4
    }

    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        bookImageView.image = nil
        titleLabel.text = nil
        authorLabel.text = nil
        currentBook = nil
        addBookHandler = nil
    }
}