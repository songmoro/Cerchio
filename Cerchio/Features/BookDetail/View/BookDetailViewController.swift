//
//  BookDetailViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class BookDetailViewController: BaseViewController<BookDetailReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    // MARK: - UI Components
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!

    // MARK: - Section & Item Types
    nonisolated enum Section: CaseIterable {
        case bookInfo
        // 추후 추가될 섹션들
        // case readingProgress
        // case quotes
        // case notes
    }

    nonisolated enum Item: Hashable {
        case bookInfo(BookDetail)
        // 추후 추가될 아이템들
        // case readingProgress(ReadingProgress)
        // case quote(Quote)
        // case note(Note)
    }

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        setupNavigationBar()
        setupCollectionView()
        setupLayout()
        configureDataSource()
    }

    private func setupNavigationBar() {
        // 즐겨찾기 버튼
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(favoriteButtonTapped)
        )

        // 삭제 버튼
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )

        navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]
    }

    @objc private func favoriteButtonTapped() {
        reactor?.action.onNext(.toggleFavorite)
    }

    @objc private func deleteButtonTapped() {
        reactor?.action.onNext(.deleteBook)
    }

    private func updateFavoriteButton(isFavorite: Bool) {
        guard let rightBarButtonItems = navigationItem.rightBarButtonItems,
              rightBarButtonItems.count >= 2 else { return }

        let favoriteButton = rightBarButtonItems[1] // 두 번째 버튼이 즐겨찾기 버튼
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.image = UIImage(systemName: imageName)
    }

    override func bind(reactor: BookDetailReactor) {
        // Action
        Observable.just(BookDetailReactor.Action.loadBookDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.bookDetail }
            .compactMap { $0 }
            .distinctUntilChanged { lhs, rhs in
                lhs.book.isbn == rhs.book.isbn
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] bookDetail in
                self?.updateSnapshot(with: bookDetail)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                // TODO: 로딩 인디케이터 처리
                print("Loading: \(isLoading)")
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.error }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                // TODO: 에러 처리
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)

        // 즐겨찾기 상태 바인딩
        reactor.state
            .map { $0.isFavorite }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButton(isFavorite: isFavorite)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Setup Methods
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true

        // 셀 등록
        collectionView.register(BookInfoCollectionViewCell.self)

        view.addSubview(collectionView)
    }

    private func setupLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        // 컴포지셔널 레이아웃 설정
        collectionView.collectionViewLayout = createCompositionalLayout()
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self else { return nil }

            let section = Section.allCases[sectionIndex]
            switch section {
            case .bookInfo:
                return self.createBookInfoSection()
            }
        }
    }

    private func createBookInfoSection() -> NSCollectionLayoutSection {
        // 도서 정보 섹션 - 전체 화면 너비 사용
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200) // 예상 높이, 자동 조정됨
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        return section
    }

    // MARK: - DataSource Configuration
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .bookInfo(let bookDetail):
                let cell: BookInfoCollectionViewCell = collectionView.dequeueReusableCell(BookInfoCollectionViewCell.self, for: indexPath)
                cell.configure(with: bookDetail)
                return cell
            }
        }
    }

    private func updateSnapshot(with bookDetail: BookDetail) {
        var snapshot = Snapshot()
        snapshot.appendSections([.bookInfo])
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Collection View Cell
final class BookInfoCollectionViewCell: UICollectionViewCell, IsIdentifiable {
    // MARK: - UI Components
    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray5
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .bold, size: 18)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let pagesLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let dateRangeLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 14)
        label.textColor = .secondaryLabel
        return label
    }()

    private let tagsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .leading
        return stackView
    }()

    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
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
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1

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
            $0.leading.top.bottom.equalToSuperview().inset(16)
            $0.width.equalToSuperview().multipliedBy(0.3)
            $0.height.equalTo(coverImageView.snp.width).multipliedBy(4.0/3.0)
        }

        // 정보 스택 뷰 (오른쪽 2/3)
        infoStackView.snp.makeConstraints {
            $0.leading.equalTo(coverImageView.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(16)
            $0.bottom.lessThanOrEqualToSuperview().inset(16)
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
        label.font = .custom(weight: .medium, size: 12)
        label.textColor = .forestGreen
        label.backgroundColor = UIColor.forestGreen.withAlphaComponent(0.1)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textAlignment = .center

        // 패딩 추가
        label.snp.makeConstraints {
            $0.height.equalTo(24)
        }

        return label
    }
}