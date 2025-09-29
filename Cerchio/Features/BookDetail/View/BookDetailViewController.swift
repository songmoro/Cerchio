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
            heightDimension: .estimated(BookDetailConstants.Layout.estimatedHeight) // 예상 높이, 자동 조정됨
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(BookDetailConstants.Layout.estimatedHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = BookDetailConstants.Layout.sectionContentInsets

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
