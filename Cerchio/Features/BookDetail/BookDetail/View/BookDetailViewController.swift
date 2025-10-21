//
//  BookDetailViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class BookDetailViewController: FullScreenNestedScrollViewController, View {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    // MARK: - ReactorKit Properties
    var disposeBag = DisposeBag()
    weak var coordinator: Coordinator?
    let navigationEvents = PublishRelay<NavigationEvent>()

    var reactor: BookDetailReactor? {
        didSet {
            guard let reactor = reactor else { return }
            if isViewLoaded {
                self.bind(reactor: reactor)
            }
        }
    }

    // MARK: - UI Components
    private var dataSource: DataSource!
    private var bookInfoView: BookInfoView?
    private var tabNavigationView: TabNavigationView<Section>?
    private var floatingActionButton: UIButton!

    // MARK: - Navigation Bar Buttons
    private var favoriteButton: UIBarButtonItem?

    // MARK: - Reading Statistics
    private var currentStatisticsPeriod: ReadingStatisticsPeriod = .today
    private var currentPeriodDate: Date = Date()

    // MARK: - Animation Control
    private var isInitialLoad = true

    // MARK: - Section & Item Types
    nonisolated enum Section: Int, Hashable {
        case readingRecords = 0
        case savedQuotes = 1
        case addQuoteAction = 2
        case photoPages = 3
        case addPhotoAction = 4
        case settings = 5

        var title: String {
            switch self {
            case .readingRecords: return String(localized: .bookDetailReadingRecords)
            case .savedQuotes: return String(localized: .bookDetailSavedQuotes)
            case .addQuoteAction: return ""
            case .photoPages: return String(localized: .bookDetailPhotos)
            case .addPhotoAction: return ""
            case .settings: return String(localized: .bookDetailSettings)
            }
        }

        // Sections visible in tab navigation (excludes action sections)
        static var visibleSections: [Section] {
            [.readingRecords, .savedQuotes, .photoPages, .settings]
        }

        // All sections for layout purposes
        static var allCases: [Section] {
            [.readingRecords, .savedQuotes, .addQuoteAction, .photoPages, .addPhotoAction, .settings]
        }
    }

    nonisolated enum Item: Hashable, Sendable {
        case readingStatistics(ReadingStatistics)
        case savedQuote(String, Int?, Date)
        case addQuoteAction
        case photoItem(String, UIImage)
        case addPhotoAction
        case settingsItem(SettingsItemType)

        func hash(into hasher: inout Hasher) {
            switch self {
            case .readingStatistics(let stats):
                hasher.combine("readingStatistics")
                hasher.combine(stats)
            case .savedQuote(let quote, let page, let date):
                hasher.combine("savedQuote")
                hasher.combine(quote)
                hasher.combine(page)
                hasher.combine(date)
            case .addQuoteAction:
                hasher.combine("addQuoteAction")
            case .photoItem(let id, _):
                hasher.combine("photoItem")
                hasher.combine(id)
            case .addPhotoAction:
                hasher.combine("addPhotoAction")
            case .settingsItem(let type):
                hasher.combine("settingsItem")
                hasher.combine(type)
            }
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            switch (lhs, rhs) {
            case (.readingStatistics(let l), .readingStatistics(let r)):
                return l == r
            case (.savedQuote(let lq, let lp, let ld), .savedQuote(let rq, let rp, let rd)):
                return lq == rq && lp == rp && ld == rd
            case (.addQuoteAction, .addQuoteAction):
                return true
            case (.photoItem(let l, _), .photoItem(let r, _)):
                return l == r
            case (.addPhotoAction, .addPhotoAction):
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
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCustomContent()
        setupBackButton()
        setupFloatingActionButton()

        if let reactor = reactor {
            bind(reactor: reactor)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.loadBookDetail)
        reactor?.action.onNext(.loadReadingStatistics)
        reactor?.action.onNext(.loadPhotos)
        reactor?.action.onNext(.loadQuotes)
        reactor?.action.onNext(.loadTags)
    }

    private func setupBackButton() {
        // Remove back button text, only show the chevron
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    private func setupFloatingActionButton() {
        floatingActionButton = UIButton(type: .custom)
        floatingActionButton.backgroundColor = .forestGreen
        floatingActionButton.setImage(UIImage(systemName: "plus"), for: .normal)
        floatingActionButton.tintColor = .white
        floatingActionButton.layer.cornerRadius = 28
        floatingActionButton.layer.shadowColor = UIColor.black.cgColor
        floatingActionButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        floatingActionButton.layer.shadowRadius = 4
        floatingActionButton.layer.shadowOpacity = 0.3

        view.addSubview(floatingActionButton)

        floatingActionButton.snp.makeConstraints {
            $0.width.height.equalTo(56)
            $0.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
        }

        // Add circular menu on tap
        let menuItems: [CircularMenuItemProtocol] = [
            CircularMenuItem(name: String(localized: .circularMenuBookDetailReadingRecord), image: UIImage(systemName: "book.fill")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                // Dismiss menu first, then show reading record entry
                self?.dismissPresentedMenuAndExecute {
                    self?.showReadingRecordEntry()
                }
            },
            CircularMenuItem(name: String(localized: .circularMenuBookDetailSaveQuote), image: UIImage(systemName: "quote.bubble.fill")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                // Dismiss menu first, then show quote entry
                self?.dismissPresentedMenuAndExecute {
                    self?.showQuoteEntry()
                }
            },
            CircularMenuItem(name: String(localized: .circularMenuBookDetailTakePhoto), image: UIImage(systemName: "camera.fill")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                // Dismiss menu first, then show photo capture
                self?.dismissPresentedMenuAndExecute {
                    self?.showPhotoCapture()
                }
            }
        ]

        CircularMenuManager.shared.addTapMenu(
            to: floatingActionButton,
            targetView: floatingActionButton,
            items: menuItems,
            presentingViewController: self
        )
    }

    // MARK: - Info View Height
    override var infoViewHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        return screenHeight * 0.50
    }

    // MARK: - Override: Create Info View
    override func createInfoView() -> UIView {
        let infoView = BookInfoView()
        self.bookInfoView = infoView

        infoView.onTagsTapped = { [weak self] in
            self?.showTagInputAlert()
        }

        infoView.onReadingInfoTapped = { [weak self] in
            guard let bookDetail = self?.reactor?.currentState.bookDetail else { return }
            self?.showReadingInfoEdit(bookDetail: bookDetail)
        }

        return infoView
    }

    // MARK: - Override: Create Sticky Tab View
    override func createStickyTabView() -> UIView {
        let tabs: [(title: String, value: Section)] = Section.visibleSections.map { ($0.title, $0) }
        let tabView = TabNavigationView<Section>(tabs: tabs)
        self.tabNavigationView = tabView

        tabView.onTabSelected = { [weak self] section in
            self?.handleTabSelection(section)
        }

        return tabView
    }

    // MARK: - Public Methods
    func setFavoriteButton(_ button: UIBarButtonItem) {
        favoriteButton = button

        favoriteButton?.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .map { BookDetailReactor.Action.toggleFavorite }
            .bind(to: reactor!.action)
            .disposed(by: disposeBag)
    }

    func setDeleteButton(_ button: UIBarButtonItem) {
        button.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.showDeleteConfirmationAlert()
            })
            .disposed(by: disposeBag)
    }

    private func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton?.image = UIImage(systemName: imageName)
    }

    // MARK: - ReactorKit Binding
    func bind(reactor: BookDetailReactor) {
        // MARK: - Actions

        // Initial load
        Observable.just(BookDetailReactor.Action.loadBookDetail)
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
                self?.updateBookInfo(with: bookDetail)
                self?.updateSnapshot(with: bookDetail)
            })
            .disposed(by: disposeBag)

        // Trigger data loading when bookDetail is set
        reactor.state
            .map { $0.bookDetail }
            .compactMap { $0 }
            .distinctUntilChanged()
            .take(1)
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] bookDetail in
                print(" BookDetail first set, loading all data")
                print(" Current tags in bookDetail: \(bookDetail.tags)")
                self?.reactor?.action.onNext(.loadReadingStatistics)
                self?.reactor?.action.onNext(.loadReadingChartData(.today))
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

        // Reading Chart Data
        reactor.state
            .map { $0.readingChartData }
            .compactMap { $0 }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .compactMap { $0 }
            .drive(onNext: { [weak self] chartData in
                self?.updateChartData(chartData)
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

        // Refresh flags
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
    }

    // MARK: - Override: Collection View Layout
    override func createCollectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self,
                  let dataSource = self.dataSource else { return nil }

            let snapshot = dataSource.snapshot()
            guard sectionIndex < snapshot.sectionIdentifiers.count else { return nil }

            let section = snapshot.sectionIdentifiers[sectionIndex]
            switch section {
            case .readingRecords:
                return self.createReadingRecordsSection()
            case .savedQuotes:
                return self.createSavedQuotesSection()
            case .addQuoteAction:
                return self.createAddQuoteActionSection()
            case .photoPages:
                return self.createPhotoPagesSection()
            case .addPhotoAction:
                return self.createAddPhotoActionSection()
            case .settings:
                return self.createSettingsSection()
            }
        }
    }

    private func handleTabSelection(_ section: Section) {
        scrollToSection(section.rawValue)
    }

    // MARK: - Override: Setup Custom Content
    override func setupCustomContent() {
        collectionView.delegate = self

        // Register cells
        collectionView.register(ReadingStatisticsCell.self)
        collectionView.register(AddActionCell.self)
        collectionView.register(SavedQuoteCell.self)
        collectionView.register(PhotoItemCell.self)
        collectionView.register(SettingsItemCell.self)

        // Register headers
        collectionView.register(
            CommonSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: CommonSectionHeader.identifier
        )

        configureDataSource()
    }
}

// MARK: - Layout
extension BookDetailViewController {
    // MARK: - Section Layouts
    private func createReadingRecordsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(220)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(220)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 24, trailing: 12)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(48)
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
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 24, trailing: 12)
        section.boundarySupplementaryItems = [CommonSectionHeader.createBoundarySupplementaryItem()]

        return section
    }

    private func createPhotoPagesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1/3)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(4)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 24, trailing: 12)
        section.orthogonalScrollingBehavior = .continuous
        section.boundarySupplementaryItems = [CommonSectionHeader.createBoundarySupplementaryItem()]

        return section
    }

    private func createAddQuoteActionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 24, trailing: 12)

        return section
    }

    private func createAddPhotoActionSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 24, trailing: 12)

        return section
    }

    private func createSettingsSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(56)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(56)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 24, trailing: 12)
        section.boundarySupplementaryItems = [CommonSectionHeader.createBoundarySupplementaryItem()]

        return section
    }
}

// MARK: - DataSource
extension BookDetailViewController {
    // MARK: - DataSource Configuration
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case .readingStatistics(_):
                let cell: ReadingStatisticsCell = collectionView.dequeueReusableCell(ReadingStatisticsCell.self, for: indexPath)
                if let chartData = self?.reactor?.currentState.readingChartData {
                    cell.configure(
                        with: chartData,
                        onPeriodChanged: { [weak self] period in
                            self?.handlePeriodChange(period)
                        },
                        onSwipe: { [weak self] direction in
                            self?.handleSwipe(direction)
                        }
                    )
                }
                return cell

            case .savedQuote(let quote, let pageNumber, let date):
                let cell: SavedQuoteCell = collectionView.dequeueReusableCell(SavedQuoteCell.self, for: indexPath)
                cell.configure(with: quote, pageNumber: pageNumber, date: date)
                cell.onActionButtonTapped = { [weak self] in
                    self?.showQuoteActionBottomSheet(for: indexPath, quote: quote, pageNumber: pageNumber, date: date)
                }
                self?.setupQuoteContextMenu(for: cell, quote: quote, pageNumber: pageNumber, date: date)
                return cell

            case .addQuoteAction:
                let cell: AddActionCell = collectionView.dequeueReusableCell(AddActionCell.self, for: indexPath)
                cell.configure(
                    icon: UIImage(systemName: "quote.bubble.fill"),
                    title: String(localized: .circularMenuBookDetailSaveQuote)
                ) { [weak self] in
                    self?.showQuoteEntry()
                }
                return cell

            case .photoItem(let photoId, let image):
                let cell: PhotoItemCell = collectionView.dequeueReusableCell(PhotoItemCell.self, for: indexPath)
                cell.configure(with: image)
                self?.setupPhotoContextMenu(for: cell, photoId: photoId, image: image)
                return cell

            case .addPhotoAction:
                let cell: AddActionCell = collectionView.dequeueReusableCell(AddActionCell.self, for: indexPath)
                cell.configure(
                    icon: UIImage(systemName: "camera.fill"),
                    title: String(localized: .circularMenuBookDetailTakePhoto)
                ) { [weak self] in
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
            guard kind == UICollectionView.elementKindSectionHeader,
                  let dataSource = self?.dataSource else { return nil }

            let snapshot = dataSource.snapshot()
            guard indexPath.section < snapshot.sectionIdentifiers.count else { return nil }

            let section = snapshot.sectionIdentifiers[indexPath.section]

            // No header for action sections
            if section == .addQuoteAction || section == .addPhotoAction {
                return nil
            }

            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: CommonSectionHeader.identifier,
                for: indexPath
            ) as! CommonSectionHeader

            switch section {
            case .readingRecords:
                header.configure(
                    title: String(localized: .bookDetailReadingRecords),
                    actionTitle: String(localized: .actionViewAll)
                )
                header.onActionTapped = { [weak self] in
                    HapticFeedbackManager.shared.impact()
                    self?.showReadingSessionList()
                }

            case .savedQuotes:
                header.configure(
                    title: String(localized: .bookDetailSavedQuotes),
                    actionTitle: String(localized: .actionViewAll)
                )
                header.onActionTapped = { [weak self] in
                    HapticFeedbackManager.shared.impact()
                    self?.showAllQuotes()
                }

            case .addQuoteAction:
                // Already handled above, but included for exhaustiveness
                return nil

            case .photoPages:
                header.configure(
                    title: String(localized: .bookDetailPhotos),
                    actionTitle: String(localized: .actionViewAll)
                )
                header.onActionTapped = { [weak self] in
                    HapticFeedbackManager.shared.impact()
                    self?.showAllPhotos()
                }

            case .addPhotoAction:
                // Already handled above, but included for exhaustiveness
                return nil

            case .settings:
                header.configure(title: String(localized: .bookDetailSettings))
            }

            return header
        }
    }

    // MARK: - UI Update Methods

    private func updateBookInfo(with bookDetail: BookDetail) {
        bookInfoView?.configure(with: bookDetail)
    }

    private func updateSnapshot(with bookDetail: BookDetail) {
        guard let dataSource = dataSource else { return }

        var snapshot = dataSource.snapshot()

        // Initialize sections if empty
        if snapshot.sectionIdentifiers.isEmpty {
            // Add main sections (always visible with headers)
            snapshot.appendSections([.readingRecords, .savedQuotes, .photoPages, .settings])

            // Settings items (always shown)
            let settingsItems: [Item] = [
                .settingsItem(.editBookInfo),
                .settingsItem(.editReadingInfo)
            ]
            snapshot.appendItems(settingsItems, toSection: .settings)

            // Note: 독서 기록 섹션은 차트 데이터 로드 후 추가
            // addQuoteAction과 addPhotoAction 섹션은 updateQuotesUI/updatePhotosUI에서 조건부로 추가
        }

        let shouldAnimate = !isInitialLoad
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
        isInitialLoad = false
    }

    private func updateReadingStatisticsUI(_ statistics: ReadingStatistics?) {
        guard let dataSource = dataSource else { return }
        var snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.readingRecords) else { return }

        let existingItems = snapshot.itemIdentifiers(inSection: .readingRecords)
        if !existingItems.isEmpty {
            snapshot.deleteItems(existingItems)
        }

        // Always show chart when statistics exist, even if chartData points are empty
        // This provides better UX by showing empty chart instead of empty state
        if let statistics = statistics {
            snapshot.appendItems([.readingStatistics(statistics)], toSection: .readingRecords)
        }

        let shouldAnimate = !isInitialLoad
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }

    private func updatePhotosUI(_ photos: [BookDetailReactor.PhotoItem]) {
        guard let dataSource = dataSource else { return }
        var snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.photoPages) else { return }

        // Clear existing items in photoPages section
        let existingItems = snapshot.itemIdentifiers(inSection: .photoPages)
        snapshot.deleteItems(existingItems)

        if photos.isEmpty {
            // photoPages section remains empty (header only)
            // Add addPhotoAction section
            if !snapshot.sectionIdentifiers.contains(.addPhotoAction) {
                // Insert addPhotoAction after photoPages
                if let settingsIndex = snapshot.sectionIdentifiers.firstIndex(of: .settings) {
                    snapshot.insertSections([.addPhotoAction], beforeSection: .settings)
                } else {
                    snapshot.appendSections([.addPhotoAction])
                }
            }

            // Clear and add item to addPhotoAction section
            if snapshot.sectionIdentifiers.contains(.addPhotoAction) {
                let existingActionItems = snapshot.itemIdentifiers(inSection: .addPhotoAction)
                snapshot.deleteItems(existingActionItems)
                snapshot.appendItems([.addPhotoAction], toSection: .addPhotoAction)
            }
        } else {
            // Add photo items to photoPages section
            let photoItems = photos.map { Item.photoItem($0.id, $0.image) }
            snapshot.appendItems(photoItems, toSection: .photoPages)

            // Remove addPhotoAction section if exists
            if snapshot.sectionIdentifiers.contains(.addPhotoAction) {
                let existingActionItems = snapshot.itemIdentifiers(inSection: .addPhotoAction)
                snapshot.deleteItems(existingActionItems)
                snapshot.deleteSections([.addPhotoAction])
            }
        }

        let shouldAnimate = !isInitialLoad
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }

    private func updateQuotesUI(_ quotes: [BookDetailReactor.QuoteItem]) {
        print(#function)
        guard let dataSource = dataSource, let _ = reactor?.currentState.bookDetail else { return }
        var snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.savedQuotes) else { return }

        // Clear existing items in savedQuotes section
        let existingItems = snapshot.itemIdentifiers(inSection: .savedQuotes)
        snapshot.deleteItems(existingItems)

        if quotes.isEmpty {
            // savedQuotes section remains empty (header only)
            // Add addQuoteAction section
            if !snapshot.sectionIdentifiers.contains(.addQuoteAction) {
                // Insert addQuoteAction after savedQuotes
                if let photoIndex = snapshot.sectionIdentifiers.firstIndex(of: .photoPages) {
                    snapshot.insertSections([.addQuoteAction], beforeSection: .photoPages)
                } else {
                    snapshot.appendSections([.addQuoteAction])
                }
            }

            // Clear and add item to addQuoteAction section
            if snapshot.sectionIdentifiers.contains(.addQuoteAction) {
                let existingActionItems = snapshot.itemIdentifiers(inSection: .addQuoteAction)
                snapshot.deleteItems(existingActionItems)
                snapshot.appendItems([.addQuoteAction], toSection: .addQuoteAction)
            }
        } else {
            // Add quote items to savedQuotes section
            let quoteItems = quotes.map { Item.savedQuote($0.quote, $0.pageNumber, $0.createdAt) }
            snapshot.appendItems(quoteItems, toSection: .savedQuotes)

            // Remove addQuoteAction section if exists
            if snapshot.sectionIdentifiers.contains(.addQuoteAction) {
                let existingActionItems = snapshot.itemIdentifiers(inSection: .addQuoteAction)
                snapshot.deleteItems(existingActionItems)
                snapshot.deleteSections([.addQuoteAction])
            }
        }

        let shouldAnimate = !isInitialLoad
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }

    private func updateTagsUI(_ tags: [BookDetailReactor.TagItem]) {
        print(" updateTagsUI called with \(tags.count) tags")
        if let bookDetail = reactor?.currentState.bookDetail {
            bookInfoView?.configure(with: bookDetail)
        }
    }

    private func updateChartData(_ chartData: ReadingChartData) {
        guard let dataSource = dataSource else { return }
        let snapshot = dataSource.snapshot()

        guard snapshot.sectionIdentifiers.contains(.readingRecords) else { return }

        let sectionIndex = Section.allCases.firstIndex(of: .readingRecords) ?? 0
        let indexPath = IndexPath(item: 0, section: sectionIndex)

        if let cell = collectionView.cellForItem(at: indexPath) as? ReadingStatisticsCell {
            cell.configure(
                with: chartData,
                onPeriodChanged: { [weak self] period in
                    self?.handlePeriodChange(period)
                },
                onSwipe: { [weak self] direction in
                    self?.handleSwipe(direction)
                }
            )
        } else {
            // Chart data is now available, refresh the reading statistics UI
            // This will add the chart cell with statistics (even if empty)
            updateReadingStatisticsUI(reactor?.currentState.readingStatistics)
        }
    }
}

// MARK: - Actions
extension BookDetailViewController {
    // MARK: - Helper Methods
    func dismissPresentedMenuAndExecute(_ action: @escaping () -> Void) {
        // Find the presented CircularMenuViewController and dismiss it
        if let presentedVC = presentedViewController {
            presentedVC.dismiss(animated: true) {
                action()
            }
        } else {
            // If no menu is presented, execute action immediately
            action()
        }
    }

    // MARK: - Chart Navigation
    func handlePeriodChange(_ period: ReadingStatisticsPeriod) {
        currentStatisticsPeriod = period
        currentPeriodDate = Date()
        reactor?.action.onNext(.loadReadingChartData(period))
    }

    func handleSwipe(_ direction: ReadingChartView.SwipeDirection) {
        let calendar = Calendar.current
        let newDate: Date

        switch currentStatisticsPeriod {
        case .today:
            // 하루 단위
            newDate = direction == .left
                ? calendar.date(byAdding: .day, value: 1, to: currentPeriodDate) ?? currentPeriodDate
                : calendar.date(byAdding: .day, value: -1, to: currentPeriodDate) ?? currentPeriodDate

        case .week:
            // 주 단위
            newDate = direction == .left
                ? calendar.date(byAdding: .weekOfYear, value: 1, to: currentPeriodDate) ?? currentPeriodDate
                : calendar.date(byAdding: .weekOfYear, value: -1, to: currentPeriodDate) ?? currentPeriodDate

        case .month:
            // 월 단위
            newDate = direction == .left
                ? calendar.date(byAdding: .month, value: 1, to: currentPeriodDate) ?? currentPeriodDate
                : calendar.date(byAdding: .month, value: -1, to: currentPeriodDate) ?? currentPeriodDate

        case .year:
            // 년 단위
            newDate = direction == .left
                ? calendar.date(byAdding: .year, value: 1, to: currentPeriodDate) ?? currentPeriodDate
                : calendar.date(byAdding: .year, value: -1, to: currentPeriodDate) ?? currentPeriodDate
        }

        currentPeriodDate = newDate
        // TODO: 날짜를 포함한 차트 데이터 로드 로직 구현 필요
        // reactor?.action.onNext(.loadReadingChartData(period: currentStatisticsPeriod, date: newDate))
        reactor?.action.onNext(.loadReadingChartData(currentStatisticsPeriod))
    }

    // MARK: - Navigation Methods
    func showReadingRecordEntry() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showReadingRecordEntry()
    }

    func showQuoteEntry() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showQuoteEntry()
    }

    func showPhotoCapture() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showPhotoCapture { [weak self] image in
            self?.reactor?.action.onNext(.savePhoto(image))
        }
    }

    func showAllQuotes() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showAllQuotes()
    }

    func showAllPhotos() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showAllPhotos()
    }

    func showReadingSessionList() {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showReadingSessionList()
    }

    // MARK: - Context Menus
    func setupPhotoContextMenu(for cell: PhotoItemCell, photoId: String, image: UIImage) {
        let menuItems = [
            CircularMenuItem(name: String(localized: .circularMenuCommonView), image: UIImage(systemName: "eye")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.showImagePreview(image)
            },
            CircularMenuItem(name: String(localized: .circularMenuCommonSave), image: UIImage(systemName: "square.and.arrow.down")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.saveImageToPhotoLibrary(image)
            },
            CircularMenuItem(name: String(localized: .circularMenuCommonDelete), image: UIImage(systemName: "trash")) { [weak self] in
                HapticFeedbackManager.shared.selection()
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

    func setupQuoteContextMenu(for cell: SavedQuoteCell, quote: String, pageNumber: Int?, date: Date) {
        let menuItems = [
            CircularMenuItem(name: String(localized: .circularMenuCommonShare), image: UIImage(systemName: "square.and.arrow.up")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.shareQuote(quote, pageNumber: pageNumber)
            },
            CircularMenuItem(name: String(localized: .circularMenuCommonEdit), image: UIImage(systemName: "pencil")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.editQuote(quote, pageNumber: pageNumber, date: date)
            },
            CircularMenuItem(name: String(localized: .circularMenuCommonDelete), image: UIImage(systemName: "trash")) { [weak self] in
                HapticFeedbackManager.shared.selection()
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
    func showImagePreview(_ image: UIImage) {
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

    @objc func dismissImagePreview() {
        dismiss(animated: true)
    }

    func saveImageToPhotoLibrary(_ image: UIImage) {
        PhotoLibraryPermissionManager.shared.handlePhotoLibraryPermission(from: self) { [weak self] granted in
            guard granted else { return }
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.imageSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc func imageSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(
            title: error == nil ? String(localized: .photoSaveSuccessTitle) : String(localized: .photoSaveFailureTitle),
            message: error == nil ? String(localized: .photoSaveSuccessMessage) : String(localized: .photoSaveFailureMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .actionConfirm), style: .default))
        present(alert, animated: true)
    }

    func showDeletePhotoConfirmation(for photoId: String) {
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
    func shareQuote(_ quote: String, pageNumber: Int?) {
        guard let reactor = reactor, let coordinator = coordinator as? BookDetailCoordinator else { return }

        let bookDetail = reactor.currentState.bookDetail
        let book = bookDetail?.book ?? reactor.currentState.book

        let quoteData = QuoteShareData(
            bookCoverImageURL: book.image,
            bookCoverImage: nil,
            bookTitle: book.customTitle ?? book.cleanTitle,
            bookAuthor: book.author,
            quote: quote,
            pageNumber: pageNumber,
            date: Date(),
            backgroundConfig: .default
        )

        coordinator.showQuoteShare(quoteData: quoteData)
    }

    func editQuote(_ quote: String, pageNumber: Int?, date: Date) {
        guard let coordinator = coordinator as? BookDetailCoordinator else { return }
        coordinator.showQuoteEdit(quote: quote, pageNumber: pageNumber, date: date)
    }

    func showDeleteQuoteConfirmation(for quote: String, date: Date) {
        let alert = UIAlertController(
            title: String(localized: .alertDeleteQuoteTitle),
            message: String(localized: .alertDeleteQuoteMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteQuote(quote, date))
        })

        present(alert, animated: true)
    }

    // MARK: - Tag Input
    func showTagInputAlert() {
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
    func showReadingInfoEdit(bookDetail: BookDetail) {
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
    func showDeleteConfirmationAlert() {
        guard let reactor = reactor else { return }
        let bookTitle = reactor.currentState.book.cleanTitle

        let messageFormat = NSLocalizedString("alert.delete_book.message_format", comment: "")
        let message = String(format: messageFormat, bookTitle)

        let alert = UIAlertController(
            title: String(localized: .alertDeleteBookTitle),
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteBook)
        })

        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDelegate
extension BookDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .photoItem(let photoId, let image):
            showPhotoActionBottomSheet(for: indexPath, photoId: photoId, image: image)

        case .settingsItem(let type):
            handleSettingsItemTap(type)

        default:
            break
        }

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

    // MARK: - Bottom Sheets

    private func showPhotoActionBottomSheet(for indexPath: IndexPath, photoId: String, image: UIImage) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoItemCell,
              let window = view.window else { return }

        let sheetHeight = view.bounds.height / 3
        let bottomSheet = PhotoActionBottomSheet(sourceView: cell, sheetHeight: sheetHeight)

        bottomSheet.onActionSelected = { [weak self] action in
            switch action {
            case .view:
                self?.showImagePreview(image)
            case .download:
                self?.saveImageToPhotoLibrary(image)
            case .delete:
                self?.showDeletePhotoConfirmation(for: photoId)
            }
        }

        bottomSheet.show(in: window)
    }

    private func showQuoteActionBottomSheet(for indexPath: IndexPath, quote: String, pageNumber: Int?, date: Date) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? SavedQuoteCell,
              let window = view.window else { return }

        let sheetHeight = view.bounds.height / 3
        let bottomSheet = QuoteActionBottomSheet(sourceView: cell, sheetHeight: sheetHeight)

        bottomSheet.onActionSelected = { [weak self] action in
            switch action {
            case .share:
                self?.shareQuote(quote, pageNumber: pageNumber)
            case .edit:
                self?.editQuote(quote, pageNumber: pageNumber, date: date)
            case .delete:
                self?.showDeleteQuoteConfirmation(for: quote, date: date)
            }
        }

        bottomSheet.show(in: window)
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
