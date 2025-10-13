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
    private let refreshControl = UIRefreshControl()

    // MARK: - Navigation Bar Buttons
    private var favoriteButton: UIBarButtonItem?

    // MARK: - Reading Statistics
    private var currentStatisticsPeriod: ReadingStatisticsPeriod = .total

    // MARK: - Section & Item Types
    nonisolated enum Section: CaseIterable {
        case bookInfo
        case readingRecords
        case savedQuotes
        case photoPages
        case settings
    }

    nonisolated enum Item: Hashable, Sendable {
        case bookInfo(BookDetail)
        case readingStatistics(ReadingStatistics)
        case addReadingRecordButton
        case savedQuote(String, Int?, Date)
        case addQuoteButton
        case photoItem(String, UIImage)
        case addPhotoButton
        case settingsItem(SettingsItemType)

        func hash(into hasher: inout Hasher) {
            switch self {
            case .bookInfo(let detail):
                hasher.combine("bookInfo")
                hasher.combine(detail)
            case .readingStatistics(let stats):
                hasher.combine("readingStatistics")
                hasher.combine(stats)
            case .addReadingRecordButton:
                hasher.combine("addReadingRecordButton")
            case .savedQuote(let quote, let page, let date):
                hasher.combine("savedQuote")
                hasher.combine(quote)
                hasher.combine(page)
                hasher.combine(date)
            case .addQuoteButton:
                hasher.combine("addQuoteButton")
            case .photoItem(let id, _):
                hasher.combine("photoItem")
                hasher.combine(id)
            case .addPhotoButton:
                hasher.combine("addPhotoButton")
            case .settingsItem(let type):
                hasher.combine("settingsItem")
                hasher.combine(type)
            }
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            switch (lhs, rhs) {
            case (.bookInfo(let l), .bookInfo(let r)):
                return l == r
            case (.readingStatistics(let l), .readingStatistics(let r)):
                return l == r
            case (.addReadingRecordButton, .addReadingRecordButton):
                return true
            case (.savedQuote(let lq, let lp, let ld), .savedQuote(let rq, let rp, let rd)):
                return lq == rq && lp == rp && ld == rd
            case (.addQuoteButton, .addQuoteButton):
                return true
            case (.photoItem(let l, _), .photoItem(let r, _)):
                return l == r
            case (.addPhotoButton, .addPhotoButton):
                return true
            case (.settingsItem(let l), .settingsItem(let r)):
                return l == r
            default:
                return false
            }
        }
    }

    nonisolated enum SettingsItemType: Hashable, Sendable {
        case editBookInfo
        case editReadingInfo
        case resetAndDelete
    }

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        setupCollectionView()
        setupLayout()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.loadBookDetail)
        reactor?.action.onNext(.loadReadingStatistics)
        reactor?.action.onNext(.loadPhotos)
        reactor?.action.onNext(.loadQuotes)
        reactor?.action.onNext(.loadTags)
    }

    // MARK: - Public Methods
    func setFavoriteButton(_ button: UIBarButtonItem) {
        favoriteButton = button

        favoriteButton?.rx.tap
            .map { BookDetailReactor.Action.toggleFavorite }
            .bind(to: reactor!.action)
            .disposed(by: disposeBag)
    }

    func setDeleteButton(_ button: UIBarButtonItem) {
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showDeleteConfirmationAlert()
            })
            .disposed(by: disposeBag)
    }

    private func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton?.image = UIImage(systemName: imageName)
    }

    override func bind(reactor: BookDetailReactor) {
        // MARK: - Actions

        // Initial load
        Observable.just(BookDetailReactor.Action.loadBookDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Refresh Control
        refreshControl.rx.controlEvent(.valueChanged)
            .map { BookDetailReactor.Action.updateBookAndReload(reactor.currentState.book) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // MARK: - State Bindings

        // BookDetail
        reactor.state
            .map { $0.bookDetail }
            .compactMap { $0 }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .compactMap { $0 }
            .drive(onNext: { [weak self] bookDetail in
                self?.updateSnapshot(with: bookDetail)
            })
            .disposed(by: disposeBag)

        // Trigger data loading when bookDetail is set (async to avoid reentrancy)
        reactor.state
            .map { $0.bookDetail }
            .compactMap { $0 }
            .distinctUntilChanged()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.reactor?.action.onNext(.loadReadingStatistics)
                self?.reactor?.action.onNext(.loadPhotos)
                self?.reactor?.action.onNext(.loadQuotes)
                self?.reactor?.action.onNext(.loadTags)
            })
            .disposed(by: disposeBag)

        // Reading Statistics
        reactor.state
            .map { $0.readingStatistics }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] statistics in
                self?.updateReadingStatisticsUI(statistics)
            })
            .disposed(by: disposeBag)

        // Photos
        reactor.state
            .map { $0.photos }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] photos in
                self?.updatePhotosUI(photos)
            })
            .disposed(by: disposeBag)

        // Quotes
        reactor.state
            .map { $0.quotes }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] quotes in
                self?.updateQuotesUI(Array(quotes))
            })
            .disposed(by: disposeBag)

        // Tags
        reactor.state
            .map { $0.tags }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] tags in
                self?.updateTagsUI(Array(tags))
            })
            .disposed(by: disposeBag)

        // Loading state - end refresh control when loading completes
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .filter { !$0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] _ in
                self?.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)

        // Error
        reactor.state
            .map { $0.error }
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: nil as Error?)
            .compactMap { $0 }
            .drive(onNext: { error in
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)

        // Favorite status
        reactor.state
            .map { $0.isFavorite }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButton(isFavorite: isFavorite)
            })
            .disposed(by: disposeBag)

        // Refresh flags - use asyncInstance to avoid reentrancy
        reactor.state
            .map { $0.shouldRefreshPhotos }
            .distinctUntilChanged()
            .filter { $0 }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.reactor?.action.onNext(.loadPhotos)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.shouldRefreshTags }
            .distinctUntilChanged()
            .filter { $0 }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.reactor?.action.onNext(.loadTags)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.shouldRefreshQuotes }
            .distinctUntilChanged()
            .filter { $0 }
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
                self?.reactor?.action.onNext(.loadQuotes)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Setup Methods
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl

        collectionView.register(BookInfoCollectionViewCell.self)
        collectionView.register(ReadingStatisticsCell.self)
        collectionView.register(AddReadingRecordButtonCell.self)
        collectionView.register(SavedQuoteCell.self)
        collectionView.register(AddQuoteButtonCell.self)
        collectionView.register(PhotoItemCell.self)
        collectionView.register(AddPhotoCell.self)
        collectionView.register(SettingsItemCell.self)

        collectionView.register(
            ReadingRecordsSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ReadingRecordsSectionHeader.identifier
        )
        collectionView.register(
            SavedQuotesSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SavedQuotesSectionHeader.identifier
        )
        collectionView.register(
            PhotosSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PhotosSectionHeader.identifier
        )
        collectionView.register(
            SettingsSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SettingsSectionHeader.identifier
        )

        view.addSubview(collectionView)
    }

    private func setupLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        collectionView.collectionViewLayout = createCompositionalLayout()
    }

    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self else { return nil }

            let section = Section.allCases[sectionIndex]
            switch section {
            case .bookInfo:
                return self.createBookInfoSection()
            case .readingRecords:
                return self.createReadingRecordsSection()
            case .savedQuotes:
                return self.createSavedQuotesSection()
            case .photoPages:
                return self.createPhotoPagesSection()
            case .settings:
                return self.createSettingsSection()
            }
        }
    }

    private func createBookInfoSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(BookDetailConstants.Layout.estimatedHeight)
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

    private func createReadingRecordsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    private func createSavedQuotesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(120)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    private func createPhotoPagesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(120),
            heightDimension: .absolute(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    private func createSettingsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(56)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(56)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return section
    }

    // MARK: - DataSource Configuration
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case .bookInfo(let bookDetail):
                let cell: BookInfoCollectionViewCell = collectionView.dequeueReusableCell(BookInfoCollectionViewCell.self, for: indexPath)
                cell.configure(with: bookDetail)
                cell.onTagsTapped = { [weak self] in
                    self?.showTagInputAlert()
                }
                cell.onReadingInfoTapped = { [weak self] in
                    self?.showReadingInfoEdit(bookDetail: bookDetail)
                }
                return cell

            case .readingStatistics(let statistics):
                let cell: ReadingStatisticsCell = collectionView.dequeueReusableCell(ReadingStatisticsCell.self, for: indexPath)
                cell.configure(with: statistics, period: self?.currentStatisticsPeriod ?? .total)
                return cell

            case .addReadingRecordButton:
                let cell: AddReadingRecordButtonCell = collectionView.dequeueReusableCell(AddReadingRecordButtonCell.self, for: indexPath)
                cell.onAddRecordTapped = { [weak self] in
                    self?.showReadingRecordEntry()
                }
                return cell

            case .savedQuote(let quote, let pageNumber, let date):
                let cell: SavedQuoteCell = collectionView.dequeueReusableCell(SavedQuoteCell.self, for: indexPath)
                cell.configure(with: quote, pageNumber: pageNumber, date: date)
                self?.setupQuoteContextMenu(for: cell, quote: quote, pageNumber: pageNumber, date: date)
                return cell

            case .addQuoteButton:
                let cell: AddQuoteButtonCell = collectionView.dequeueReusableCell(AddQuoteButtonCell.self, for: indexPath)
                cell.onAddQuoteTapped = { [weak self] in
                    self?.showQuoteEntry()
                }
                return cell

            case .photoItem(let photoId, let image):
                let cell: PhotoItemCell = collectionView.dequeueReusableCell(PhotoItemCell.self, for: indexPath)
                cell.configure(with: image)
                cell.onPhotoTapped = { [weak self] image in
                    self?.showImagePreview(image)
                }
                self?.setupPhotoContextMenu(for: cell, photoId: photoId, image: image)
                return cell

            case .addPhotoButton:
                let cell: AddPhotoCell = collectionView.dequeueReusableCell(AddPhotoCell.self, for: indexPath)
                cell.onAddPhotoTapped = { [weak self] in
                    self?.showPhotoCapture()
                }
                return cell

            case .settingsItem(let type):
                let cell: SettingsItemCell = collectionView.dequeueReusableCell(SettingsItemCell.self, for: indexPath)

                switch type {
                case .editBookInfo:
                    cell.configure(
                        icon: UIImage(systemName: "pencil"),
                        title: String(localized: .bookDetailEditBookInfo)
                    )
                case .editReadingInfo:
                    cell.configure(
                        icon: UIImage(systemName: "book"),
                        title: String(localized: .bookDetailEditReadingInfo)
                    )
                case .resetAndDelete:
                    cell.configure(
                        icon: UIImage(systemName: "trash"),
                        title: String(localized: .bookDetailResetAndDelete)
                    )
                }

                return cell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }

            let section = Section.allCases[indexPath.section]

            switch section {
            case .readingRecords:
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: ReadingRecordsSectionHeader.identifier,
                    for: indexPath
                ) as! ReadingRecordsSectionHeader

                header.onViewAllTapped = { [weak self] in
                    self?.showReadingSessionList()
                }

                header.onPeriodChanged = { [weak self] period in
                    self?.handlePeriodChange(period)
                }

                let hasRecords = self?.reactor?.currentState.readingStatistics?.totalSessions ?? 0 > 0
                header.configure(hasRecords: hasRecords)

                return header

            case .savedQuotes:
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: SavedQuotesSectionHeader.identifier,
                    for: indexPath
                ) as! SavedQuotesSectionHeader

                header.onViewAllTapped = { [weak self] in
                    self?.showAllQuotes()
                }
                return header

            case .photoPages:
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: PhotosSectionHeader.identifier,
                    for: indexPath
                ) as! PhotosSectionHeader

                header.onViewAllTapped = { [weak self] in
                    self?.showAllPhotos()
                }
                return header

            case .settings:
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: SettingsSectionHeader.identifier,
                    for: indexPath
                ) as! SettingsSectionHeader

                header.configure(title: String(localized: .bookDetailSettings))
                return header

            default:
                return nil
            }
        }
    }

    // MARK: - UI Update Methods

    private func updateSnapshot(with bookDetail: BookDetail) {
        print(#function)
        guard let dataSource = dataSource else { return }

        var snapshot = dataSource.snapshot()

        // 섹션이 없으면 초기화
        if snapshot.sectionIdentifiers.isEmpty {
            snapshot.appendSections([.bookInfo, .readingRecords, .savedQuotes, .photoPages, .settings])
            snapshot.appendItems([.addQuoteButton], toSection: .savedQuotes)
            snapshot.appendItems([.addPhotoButton], toSection: .photoPages)

            // Settings items
            let settingsItems: [Item] = [
                .settingsItem(.editBookInfo),
                .settingsItem(.editReadingInfo),
                .settingsItem(.resetAndDelete)
            ]
            snapshot.appendItems(settingsItems, toSection: .settings)
        }

        // bookInfo 섹션만 업데이트 (기존 데이터 유지)
        let existingBookInfoItems = snapshot.itemIdentifiers(inSection: .bookInfo)
        if !existingBookInfoItems.isEmpty {
            snapshot.deleteItems(existingBookInfoItems)
        }
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateReadingStatisticsUI(_ statistics: ReadingStatistics?) {
        guard let dataSource = dataSource else { return }
        var snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.readingRecords) else { return }

        let existingItems = snapshot.itemIdentifiers(inSection: .readingRecords)
        if !existingItems.isEmpty {
            snapshot.deleteItems(existingItems)
        }

        if let statistics = statistics, !statistics.isEmpty {
            snapshot.appendItems([.readingStatistics(statistics)], toSection: .readingRecords)
        } else {
            snapshot.appendItems([.addReadingRecordButton], toSection: .readingRecords)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updatePhotosUI(_ photos: [BookDetailReactor.PhotoItem]) {
        guard let dataSource = dataSource else { return }
        var snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.photoPages) else { return }

        let existingItems = snapshot.itemIdentifiers(inSection: .photoPages)
        let photoItemsToRemove = existingItems.filter {
            if case .photoItem = $0 { return true }
            return false
        }
        snapshot.deleteItems(photoItemsToRemove)

        if let addButtonIndex = snapshot.itemIdentifiers(inSection: .photoPages).firstIndex(where: {
            if case .addPhotoButton = $0 { return true }
            return false
        }) {
            let addButtonItem = snapshot.itemIdentifiers(inSection: .photoPages)[addButtonIndex]
            let photoItems = photos.map { Item.photoItem($0.id, $0.image) }
            snapshot.insertItems(photoItems, afterItem: addButtonItem)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateQuotesUI(_ quotes: [RealmQuote]) {
        print(#function)
        guard let dataSource = dataSource, let _ = reactor?.currentState.bookDetail else { return }
        var snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.savedQuotes) else { return }

        let existingItems = snapshot.itemIdentifiers(inSection: .savedQuotes)
        snapshot.deleteItems(existingItems)

        var quoteItems: [Item] = []
        if quotes.isEmpty {
            quoteItems.append(.addQuoteButton)
        } else {
            let maxQuotes = min(quotes.count, 3)
            for i in 0..<maxQuotes {
                let quote = quotes[i]
                quoteItems.append(.savedQuote(quote.quote, quote.pageNumber, quote.createdAt))
            }
        }
        snapshot.appendItems(quoteItems, toSection: .savedQuotes)

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func updateTagsUI(_ tags: [RealmTag]) {
        guard let reactor = reactor, let bookDetail = reactor.currentState.bookDetail else { return }

        let tagNames = tags.map { $0.tagName }
        let updatedBookDetail = BookDetail(
            book: bookDetail.book,
            totalPages: bookDetail.totalPages,
            startDate: bookDetail.startDate,
            endDate: bookDetail.endDate,
            tags: tagNames
        )

        var snapshot = dataSource.snapshot()
        let currentItems = snapshot.itemIdentifiers(inSection: .bookInfo)
        snapshot.deleteItems(currentItems)
        snapshot.appendItems([.bookInfo(updatedBookDetail)], toSection: .bookInfo)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Navigation Methods

    private func showReadingRecordEntry() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showReadingRecordEntry()
    }

    private func showQuoteEntry() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showQuoteEntry()
    }

    private func showPhotoCapture() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showPhotoCapture { [weak self] image in
            self?.reactor?.action.onNext(.savePhoto(image))
        }
    }

    private func showAllQuotes() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showAllQuotes()
    }

    private func showAllPhotos() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showAllPhotos()
    }

    private func showReadingSessionList() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showReadingSessionList()
    }

    // MARK: - Context Menus

    private func setupPhotoContextMenu(for cell: PhotoItemCell, photoId: String, image: UIImage) {
        let menuItems = [
            CircularMenuItem(name: "보기", image: UIImage(systemName: "eye")) { [weak self] in
                self?.showImagePreview(image)
            },
            CircularMenuItem(name: "저장", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] in
                self?.saveImageToPhotoLibrary(image)
            },
            CircularMenuItem(name: "삭제", image: UIImage(systemName: "trash")) { [weak self] in
                self?.showDeletePhotoConfirmation(for: photoId)
            }
        ]

        let highlightConfig = ViewHighlightConfiguration.withContextualRotation()
        CircularMenuManager.shared.addLongPressMenu(
            to: cell,
            targetView: cell,
            items: menuItems,
            presentingViewController: self,
            minimumPressDuration: 0.5,
            highlightConfiguration: highlightConfig
        )
    }

    private func setupQuoteContextMenu(for cell: SavedQuoteCell, quote: String, pageNumber: Int?, date: Date) {
        let menuItems = [
            CircularMenuItem(name: "공유", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] in
                self?.shareQuote(quote, pageNumber: pageNumber)
            },
            CircularMenuItem(name: "수정", image: UIImage(systemName: "pencil")) { [weak self] in
                self?.editQuote(quote, pageNumber: pageNumber, date: date)
            },
            CircularMenuItem(name: "삭제", image: UIImage(systemName: "trash")) { [weak self] in
                self?.showDeleteQuoteConfirmation(for: quote, date: date)
            }
        ]

        let highlightConfig = ViewHighlightConfiguration.withCustomRotation(angle: -5.0)
        CircularMenuManager.shared.addLongPressMenu(
            to: cell,
            targetView: cell,
            items: menuItems,
            presentingViewController: self,
            minimumPressDuration: 0.5,
            highlightConfiguration: highlightConfig
        )
    }

    // MARK: - Image Actions

    private func showImagePreview(_ image: UIImage) {
        let previewVC = UIViewController()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black

        previewVC.view = imageView
        previewVC.modalPresentationStyle = .fullScreen

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissImagePreview))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)

        present(previewVC, animated: true)
    }

    @objc private func dismissImagePreview() {
        dismiss(animated: true)
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        PhotoLibraryPermissionManager.shared.handlePhotoLibraryPermission(from: self) { [weak self] granted in
            guard granted else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.imageSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc private func imageSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(
            title: error == nil ? String(localized: .photoSaveSuccessTitle) : String(localized: .photoSaveFailureTitle),
            message: error == nil ? String(localized: .photoSaveSuccessMessage) : String(localized: .photoSaveFailureMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .actionConfirm), style: .default))
        present(alert, animated: true)
    }

    private func showDeletePhotoConfirmation(for photoId: String) {
        let alert = UIAlertController(
            title: String(localized: .photoDeleteConfirmationTitle),
            message: String(localized: .photoDeleteConfirmationMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deletePhoto(photoId))
        })

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Quote Actions

    private func shareQuote(_ quote: String, pageNumber: Int?) {
        guard let reactor = reactor, let coordinator = coordinator as? BookDetailCoordinator else { return }

        let bookDetail = reactor.currentState.bookDetail
        let book = bookDetail?.book ?? reactor.currentState.book

        let quoteData = QuoteShareData(
            bookCoverImageURL: book.image,
            bookCoverImage: nil,
            bookTitle: book.title,
            bookAuthor: book.author,
            quote: quote,
            pageNumber: pageNumber,
            date: Date(),
            backgroundConfig: .default
        )

        coordinator.showQuoteShare(quoteData: quoteData)
    }

    private func editQuote(_ quote: String, pageNumber: Int?, date: Date) {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showQuoteEdit(quote: quote, pageNumber: pageNumber, date: date)
    }

    private func showDeleteQuoteConfirmation(for quote: String, date: Date) {
        let alert = UIAlertController(
            title: "문장 삭제",
            message: "이 문장을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteQuote(quote, date))
        })

        present(alert, animated: true)
    }

    // MARK: - Tag Input

    private func showTagInputAlert() {
        guard let reactor = reactor else { return }
        let currentTags = reactor.currentState.tags.map { $0.tagName }

        let tagEditVC = TagEditViewController()
        tagEditVC.configure(currentTags: currentTags, allTags: currentTags)
        tagEditVC.onTagsSaved = { [weak self] tags in
            self?.reactor?.action.onNext(.saveTags(tags))
        }

        let navController = UINavigationController(rootViewController: tagEditVC)
        present(navController, animated: true)
    }

    // MARK: - Reading Info Edit

    private func showReadingInfoEdit(bookDetail: BookDetail) {
        let readingInfoEditVC = ReadingInfoEditViewController()
        readingInfoEditVC.configure(
            totalPages: bookDetail.totalPages,
            startDate: bookDetail.startDate,
            endDate: bookDetail.endDate
        )
        readingInfoEditVC.onSaved = { [weak self] totalPages, startDate, endDate in
            self?.reactor?.action.onNext(.updateReadingInfo(totalPages: totalPages, startDate: startDate, endDate: endDate))
        }

        let navController = UINavigationController(rootViewController: readingInfoEditVC)
        present(navController, animated: true)
    }

    // MARK: - Delete Confirmation

    private func showDeleteConfirmationAlert() {
        guard let reactor = reactor else { return }
        let bookTitle = reactor.currentState.book.cleanTitle

        let alert = UIAlertController(
            title: "도서 삭제",
            message: "'\(bookTitle)'\n이 책과 관련된 모든 데이터(사진, 문장, 태그)가 함께 삭제됩니다.\n\n이 작업은 되돌릴 수 없습니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "계속 보기", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteBook)
        })

        present(alert, animated: true)
    }

    private func handlePeriodChange(_ period: ReadingStatisticsPeriod) {
        currentStatisticsPeriod = period

        let sectionIndex = Section.allCases.firstIndex(of: .readingRecords) ?? 0
        let indexPath = IndexPath(item: 0, section: sectionIndex)

        if let cell = collectionView.cellForItem(at: indexPath) as? ReadingStatisticsCell {
            cell.updatePeriod(period)
        }
    }
}

// MARK: - UICollectionViewDelegate
extension BookDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .savedQuote(let quote, let pageNumber, let date):
            editQuote(quote, pageNumber: pageNumber, date: date)

        case .settingsItem(let type):
            handleSettingsItemTap(type)

        default:
            break
        }

        // Deselect cell
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    private func handleSettingsItemTap(_ type: SettingsItemType) {
        switch type {
        case .editBookInfo:
            showEditBookInfo()
        case .editReadingInfo:
            showReadingInfoEditFromSettings()
        case .resetAndDelete:
            showResetAndDelete()
        }
    }

    // MARK: - Settings Actions
    private func showEditBookInfo() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showEditBookInfo()
    }

    private func showReadingInfoEditFromSettings() {
        guard let bookDetail = reactor?.currentState.bookDetail else { return }
        showReadingInfoEdit(bookDetail: bookDetail)
    }

    private func showResetAndDelete() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showResetAndDelete()
    }
}
