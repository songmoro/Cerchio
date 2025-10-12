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
import RealmSwift

final class BookDetailViewController: BaseViewController<BookDetailReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    // MARK: - UI Components
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!
    private let refreshControl = UIRefreshControl()

    // MARK: - Child Coordinators
    private var childCoordinators: [Coordinator] = []

    // MARK: - Navigation Bar Buttons
    private var favoriteButton: UIBarButtonItem?

    // MARK: - Dependencies
    private var serviceFactory: ServiceFactory?
    private var service: BookDetailService?

    // MARK: - Image Storage
    private var photoImages: [String: UIImage] = [:]  // photoId -> UIImage
    private let imageQueue = DispatchQueue(label: "com.cerchio.bookDetail.imageQueue", attributes: .concurrent)

    // MARK: - Reading Statistics
    private var currentStatisticsPeriod: ReadingStatisticsPeriod = .total
    
    // MARK: - Section & Item Types
    nonisolated enum Section: CaseIterable {
        case bookInfo
        case readingRecords
        case savedQuotes
        case photoPages
    }
    
    nonisolated enum Item: Hashable, Sendable {
        case bookInfo(BookDetail)
        case readingStatistics(ReadingStatistics)
        case readingRecord(String, Date) // 독서 기록 내용, 생성 날짜
        case addReadingRecordButton // 독서 기록 추가 버튼
        case savedQuote(String, Int?, Date) // 문장 텍스트, 페이지, 저장 날짜
        case addQuoteButton // 문장 추가 버튼
        case photoItem(String) // 사진 ID (UIImage 대신 ID만 저장)
        case addPhotoButton // 사진 추가 버튼
        case photoLoadingIndicator // 사진 로딩 인디케이터

        func hash(into hasher: inout Hasher) {
            switch self {
            case .bookInfo(let detail):
                hasher.combine("bookInfo")
                hasher.combine(detail)
            case .readingStatistics(let stats):
                hasher.combine("readingStatistics")
                hasher.combine(stats)
            case .readingRecord(let content, let date):
                hasher.combine("readingRecord")
                hasher.combine(content)
                hasher.combine(date)
            case .addReadingRecordButton:
                hasher.combine("addReadingRecordButton")
            case .savedQuote(let quote, let page, let date):
                hasher.combine("savedQuote")
                hasher.combine(quote)
                hasher.combine(page)
                hasher.combine(date)
            case .addQuoteButton:
                hasher.combine("addQuoteButton")
            case .photoItem(let photoId):
                hasher.combine("photoItem")
                hasher.combine(photoId)
            case .addPhotoButton:
                hasher.combine("addPhotoButton")
            case .photoLoadingIndicator:
                hasher.combine("photoLoadingIndicator")
            }
        }

        static func == (lhs: Item, rhs: Item) -> Bool {
            switch (lhs, rhs) {
            case (.bookInfo(let l), .bookInfo(let r)):
                return l == r
            case (.readingStatistics(let l), .readingStatistics(let r)):
                return l == r
            case (.readingRecord(let lc, let ld), .readingRecord(let rc, let rd)):
                return lc == rc && ld == rd
            case (.addReadingRecordButton, .addReadingRecordButton):
                return true
            case (.savedQuote(let lq, let lp, let ld), .savedQuote(let rq, let rp, let rd)):
                return lq == rq && lp == rp && ld == rd
            case (.addQuoteButton, .addQuoteButton):
                return true
            case (.photoItem(let l), .photoItem(let r)):
                return l == r
            case (.addPhotoButton, .addPhotoButton):
                return true
            case (.photoLoadingIndicator, .photoLoadingIndicator):
                return true
            default:
                return false
            }
        }
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

        // 화면이 다시 나타날 때마다 최신 도서 정보 로드
        reloadBookDetailData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // 화면을 완전히 벗어났을 때 (pop)
        if isMovingFromParent {
            // 이미지 딕셔너리 정리
            imageQueue.async(flags: .barrier) { [weak self] in
                self?.photoImages.removeAll()
            }
        }
    }

    private func reloadBookDetailData() {
        guard let reactor = reactor,
              let serviceFactory = serviceFactory else {
            refreshControl.endRefreshing()
            return
        }

        let bookRepository = serviceFactory.createBookRepository()
        bookRepository.getBookByISBN(reactor.currentState.book.isbn)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] updatedBook in
                guard let updatedBook = updatedBook else {
                    self?.refreshControl.endRefreshing()
                    return
                }
                // Reactor의 book을 업데이트하고 bookDetail을 다시 로드
                self?.reactor?.action.onNext(.updateBookAndReload(updatedBook))
                self?.refreshControl.endRefreshing()
            })
            .disposed(by: disposeBag)
    }

    
    // MARK: - Public Methods
    func setFavoriteButton(_ button: UIBarButtonItem) {
        favoriteButton = button

        // Rx 바인딩
        favoriteButton?.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.reactor?.action.onNext(.toggleFavorite)
            })
            .disposed(by: disposeBag)
    }

    func setDeleteButton(_ button: UIBarButtonItem) {
        // Rx 바인딩
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showDeleteConfirmationAlert()
            })
            .disposed(by: disposeBag)
    }

    func setServiceFactory(_ factory: ServiceFactory) {
        serviceFactory = factory
        service = BookDetailService(serviceFactory: factory)
    }

    private func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton?.image = UIImage(systemName: imageName)
    }
    
    override func bind(reactor: BookDetailReactor) {
        // Action
        Observable.just(BookDetailReactor.Action.loadBookDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Refresh Control
        refreshControl.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] in
                self?.reloadBookDetailData()
            })
            .disposed(by: disposeBag)

        // State - BookDetail (use Driver for main thread guarantee)
        reactor.state
            .map { $0.bookDetail }
            .compactMap { $0 }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .compactMap { $0 }
            .drive(onNext: { [weak self] bookDetail in
                self?.updateSnapshot(with: bookDetail)
                self?.loadPhotosAndUpdateUI()
                self?.loadQuotesAndUpdateUI()
                self?.loadTagsAndUpdateUI()

                // 독서 통계 로드
                self?.reactor?.action.onNext(.loadReadingStatistics)
            })
            .disposed(by: disposeBag)

        // State - Reading Statistics
        reactor.state
            .map { $0.readingStatistics }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] statistics in
                self?.updateReadingStatisticsUI(statistics)
            })
            .disposed(by: disposeBag)

        // State - Loading
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { isLoading in
                // TODO: 로딩 인디케이터 처리
                print("Loading: \(isLoading)")
            })
            .disposed(by: disposeBag)

        // State - Error
        reactor.state
            .map { $0.error }
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: nil as Error?)
            .compactMap { $0 }
            .drive(onNext: { error in
                // TODO: 에러 처리
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)

        // State - Favorite status
        reactor.state
            .map { $0.isFavorite }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButton(isFavorite: isFavorite)
            })
            .disposed(by: disposeBag)

        // State - Book deleted
        // Coordinator가 직접 구독하므로 ViewController에서는 처리하지 않음
    }
    
    // MARK: - Setup Methods
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.refreshControl = refreshControl

        // 셀 등록
        collectionView.register(BookInfoCollectionViewCell.self)
        collectionView.register(ReadingStatisticsCell.self)
        collectionView.register(AddReadingRecordButtonCell.self)
        collectionView.register(SavedQuoteCell.self)
        collectionView.register(AddQuoteButtonCell.self)
        collectionView.register(PhotoItemCell.self)
        collectionView.register(AddPhotoCell.self)
        collectionView.register(PhotoLoadingCell.self)

        // 헤더 등록
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
            case .readingRecords:
                return self.createReadingRecordsSection()
            case .savedQuotes:
                return self.createSavedQuotesSection()
            case .photoPages:
                return self.createPhotoPagesSection()
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

    private func createReadingRecordsSection() -> NSCollectionLayoutSection {
        // 독서 기록 섹션 - 1열 레이아웃
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

        // 섹션 헤더 추가
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
        // 저장한 문장 섹션 - 1열 레이아웃
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0), // 1열
            heightDimension: .estimated(120) // 예상 높이
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

        // 섹션 헤더 추가
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
        // 찍은 사진 섹션 - Orthogonal 가로 스크롤
        // 아이템: 정사각형 (1:1 비율)
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(120),
            heightDimension: .absolute(120)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 8)

        // 그룹: 가로로 스크롤되는 아이템들
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .estimated(120),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

        // Orthogonal 스크롤 활성화
        section.orthogonalScrollingBehavior = .continuous

        // 섹션 헤더 추가
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

            case .readingRecord(let content, let date):
                let cell: SavedQuoteCell = collectionView.dequeueReusableCell(SavedQuoteCell.self, for: indexPath)
                cell.configure(with: content, pageNumber: nil, date: date)
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

                // 롱프레스 컨텍스트 메뉴 설정
                self?.setupQuoteContextMenu(for: cell, quote: quote, pageNumber: pageNumber, date: date)

                return cell

            case .addQuoteButton:
                let cell: AddQuoteButtonCell = collectionView.dequeueReusableCell(AddQuoteButtonCell.self, for: indexPath)
                cell.onAddQuoteTapped = { [weak self] in
                    self?.showQuoteEntry()
                }
                return cell

            case .photoItem(let photoId):
                let cell: PhotoItemCell = collectionView.dequeueReusableCell(PhotoItemCell.self, for: indexPath)

                // 딕셔너리에서 이미지 가져오기
                let image = self?.imageQueue.sync {
                    self?.photoImages[photoId]
                }

                if let image = image {
                    cell.configure(with: image)
                } else {
                    // 이미지가 아직 로드되지 않은 경우 (비동기 로딩 중)
                    cell.configure(with: nil)
                }

                cell.onPhotoTapped = { [weak self] image in
                    self?.showImagePreview(image)
                }

                // 컨텍스트 메뉴 설정 (photoId 기반)
                self?.setupPhotoContextMenu(for: cell, photoId: photoId)

                return cell

            case .addPhotoButton:
                let cell: AddPhotoCell = collectionView.dequeueReusableCell(AddPhotoCell.self, for: indexPath)
                cell.onAddPhotoTapped = { [weak self] in
                    self?.showPhotoCapture()
                }
                return cell

            case .photoLoadingIndicator:
                let cell: PhotoLoadingCell = collectionView.dequeueReusableCell(PhotoLoadingCell.self, for: indexPath)
                return cell
            }
        }

        // 헤더 supplementary view 설정
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

                // 통계 데이터가 있는지 확인
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

            default:
                return nil
            }
        }
    }
    
    private func updateSnapshot(with bookDetail: BookDetail) {
        var snapshot = Snapshot()
        snapshot.appendSections([.bookInfo, .readingRecords, .savedQuotes, .photoPages])

        // 책 정보
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        // 독서 기록 (별도 로드 후 업데이트, 초기에는 비워둠)
        // updateReadingStatisticsUI에서 처리

        // 저장한 문장 (기본 빈 데이터, 실제 데이터는 별도 로드)
        snapshot.appendItems([.savedQuote("", nil, Date())], toSection: .savedQuotes)

        // 찍은 사진 (기본 빈 데이터, 실제 데이터는 별도 로드)
        snapshot.appendItems([.addPhotoButton], toSection: .photoPages)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Navigation Methods
    private func showReadingRecordEntry() {
        guard let reactor = reactor, let serviceFactory = serviceFactory else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let readingRecordCoordinator = ReadingRecordCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: ReadingRecordCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: serviceFactory
            )
        )

        addChildCoordinator(readingRecordCoordinator)

        readingRecordCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .recordSaved(let content):
                    print("✅ Reading record saved: \(content)")
                case .cancelled:
                    print("📝 Reading record cancelled")
                }
                self?.removeChildCoordinator(readingRecordCoordinator)
            })
            .disposed(by: disposeBag)

        readingRecordCoordinator.start()
    }

    private func showQuoteEntry() {
        guard let reactor = reactor, let serviceFactory = serviceFactory else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: QuoteSaveCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: serviceFactory
            )
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quoteSaved(let quote):
                    print("✅ Quote saved: \(quote)")
                    self?.loadQuotesAndUpdateUI()
                case .cancelled:
                    print("📝 Quote save cancelled")
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }
    
    private func showPhotoCapture() {
        print("사진 촬영 화면으로 이동")
        
        CameraPermissionManager.shared.handleCameraPermission(from: self) { [weak self] granted in
            guard granted else {
                print("❌ Camera permission denied")
                return
            }
            
            self?.presentCameraViewController()
        }
    }
    
    private func presentCameraViewController() {
        let cameraVC = CameraViewController()
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    private func savePhoto(_ image: UIImage) {
        guard let reactor = reactor,
              let service = service else { return }

        let bookId = String(describing: reactor.currentState.book.id)

        service.savePhoto(image, bookId: bookId)
            .asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { [weak self] _ in
                print("✅ Photo saved successfully")
                self?.loadPhotosAndUpdateUI()
            })
            .disposed(by: disposeBag)
    }
    
    private func loadPhotosAndUpdateUI() {
        guard let reactor = reactor,
              let service = service else { return }

        let bookId = String(describing: reactor.currentState.book.id)

        service.loadPhotos(bookId: bookId)
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] photos in
                self?.updateSnapshotWithPhotos(
                    bookDetail: self?.reactor?.currentState.bookDetail,
                    photos: photos
                )
            })
            .disposed(by: disposeBag)
    }

    private func loadQuotesAndUpdateUI() {
        guard let reactor = reactor,
              let service = service else { return }

        let bookId = String(describing: reactor.currentState.book.id)

        service.loadQuotes(bookId: bookId)
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] quotes in
                self?.updateSnapshotWithAllData(
                    bookDetail: self?.reactor?.currentState.bookDetail,
                    quotes: quotes,
                    photos: nil
                )
            })
            .disposed(by: disposeBag)
    }

    private func updateSnapshotWithPhotos(bookDetail: BookDetail?, photos: [RealmPhoto]) {
        guard let bookDetail = bookDetail else { return }
        let bookId = String(describing: bookDetail.book.id)

        // 문장 데이터도 함께 로드해서 전체 업데이트
        do {
            let realm = try Realm()
            let quotes = realm.objects(RealmQuote.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)
            let quoteArray = Array(quotes)
            
            updateSnapshotWithAllData(
                bookDetail: bookDetail,
                quotes: quoteArray,
                photos: photos
            )
        } catch {
            print("❌ Failed to load quotes during photo update: \(error.localizedDescription)")
            updateSnapshotWithAllData(
                bookDetail: bookDetail,
                quotes: [],
                photos: photos
            )
        }
    }

    private func updateSnapshotWithAllData(bookDetail: BookDetail?, quotes: [RealmQuote], photos: [RealmPhoto]?) {
        guard let bookDetail = bookDetail else { return }

        var snapshot = Snapshot()
        snapshot.appendSections([.bookInfo, .readingRecords, .savedQuotes, .photoPages])

        // 책 정보
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        // 독서 기록 - 추가 버튼만 표시 (실제 데이터는 추후 구현)
        snapshot.appendItems([.addReadingRecordButton], toSection: .readingRecords)

        // 저장한 문장 - 최대 3개 또는 문장이 없으면 추가 버튼만
        var quoteItems: [Item] = []
        if quotes.isEmpty {
            // 문장이 없으면 추가 버튼만 표시
            quoteItems.append(.addQuoteButton)
        } else {
            // 문장이 있으면 최대 3개까지 표시
            let maxQuotes = min(quotes.count, 3)
            for i in 0..<maxQuotes {
                let quote = quotes[i]
                quoteItems.append(.savedQuote(quote.quote, quote.pageNumber, quote.createdAt))
            }
        }
        snapshot.appendItems(quoteItems, toSection: .savedQuotes)

        // 찍은 사진 - 추가 버튼과 로딩 인디케이터 먼저 표시, 이미지는 비동기 로드
        var photoItems: [Item] = []
        photoItems.append(.addPhotoButton)
        photoItems.append(.photoLoadingIndicator)
        snapshot.appendItems(photoItems, toSection: .photoPages)

        // 스냅샷 먼저 적용
        dataSource.apply(snapshot, animatingDifferences: true)

        // 사진은 비동기로 로드
        if let photos = photos {
            loadPhotosAsync(photos: photos)
        } else {
            loadPhotosFromRealm()
        }
    }

    /// 비동기로 사진 로드
    /// - 메인: Realm 경로 추출, photoId만 스냅샷에 추가
    /// - 백그라운드: 이미지 로딩 및 딕셔너리 저장
    private func loadPhotosAsync(photos: [RealmPhoto]) {
        // 메인 스레드에서 ID와 경로 추출 (가벼운 작업)
        let sortedPhotos = photos.sorted { $0.createdAt > $1.createdAt }
        let photoData = sortedPhotos.map { (id: String(describing: $0.id), path: $0.localImagePath) }
        let photoIds = photoData.map { $0.id }

        // photoId만 먼저 스냅샷에 추가
        updateSnapshotWithPhotoIds(photoIds)

        // 백그라운드에서 이미지 병렬 로드
        Task { [weak self] in
            guard let self = self else { return }

            await withTaskGroup(of: (String, UIImage?).self) { group in
                for data in photoData {
                    group.addTask {
                        let image = await ImageStorageManager.shared.loadImage(fromPath: data.path)
                        return (data.id, image)
                    }
                }

                for await (photoId, image) in group {
                    guard let image = image else { continue }

                    // 이미지 딕셔너리에 저장
                    self.imageQueue.async(flags: .barrier) { [weak self] in
                        self?.photoImages[photoId] = image
                    }
                }
            }

            // 모든 이미지 로딩 완료 후 UI 갱신
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                var snapshot = self.dataSource.snapshot()
                let photoItems = snapshot.itemIdentifiers(inSection: .photoPages).filter {
                    if case .photoItem = $0 { return true }
                    return false
                }
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems(photoItems)
                } else {
                    snapshot.reloadItems(photoItems)
                }
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }

    /// Service를 통해 Realm에서 사진 로드 후 이미지 로딩
    private func loadPhotosFromRealm() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // 메인 스레드에서 Realm 접근하여 ID와 경로 추출
                let photoData = try await MainActor.run {
                    let realm = try Realm()
                    let photos = realm.objects(RealmPhoto.self)
                        .filter("bookId == %@", bookId)
                        .sorted(byKeyPath: "createdAt", ascending: false)

                    return Array(photos.map { (id: String(describing: $0.id), path: $0.localImagePath) })
                }

                let photoIds = photoData.map { $0.id }

                // photoId만 먼저 스냅샷에 추가
                await MainActor.run { [weak self] in
                    self?.updateSnapshotWithPhotoIds(photoIds)
                }

                // 백그라운드에서 이미지 병렬 로드
                await withTaskGroup(of: (String, UIImage?).self) { group in
                    for data in photoData {
                        group.addTask {
                            let image = await ImageStorageManager.shared.loadImage(fromPath: data.path)
                            return (data.id, image)
                        }
                    }

                    for await (photoId, image) in group {
                        guard let image = image else { continue }

                        // 이미지 딕셔너리에 저장
                        self.imageQueue.async(flags: .barrier) { [weak self] in
                            self?.photoImages[photoId] = image
                        }
                    }
                }

                // 모든 이미지 로딩 완료 후 UI 갱신
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    var snapshot = self.dataSource.snapshot()
                    let photoItems = snapshot.itemIdentifiers(inSection: .photoPages).filter {
                        if case .photoItem = $0 { return true }
                        return false
                    }
                    if #available(iOS 15.0, *) {
                        snapshot.reconfigureItems(photoItems)
                    } else {
                        snapshot.reloadItems(photoItems)
                    }
                    self.dataSource.apply(snapshot, animatingDifferences: false)
                }
            } catch {
                print("❌ Failed to load photos: \(error.localizedDescription)")
            }
        }
    }

    /// PhotoId 목록으로 snapshot 업데이트 (메인 스레드에서만 호출)
    private func updateSnapshotWithPhotoIds(_ photoIds: [String]) {
        var snapshot = dataSource.snapshot()
        let currentPhotoItems = snapshot.itemIdentifiers(inSection: .photoPages)

        // 로딩 인디케이터 제거
        let loadingIndicatorItems = currentPhotoItems.filter {
            if case .photoLoadingIndicator = $0 { return true }
            return false
        }
        snapshot.deleteItems(loadingIndicatorItems)

        // 기존 사진 아이템 제거 (추가 버튼 제외)
        let photoItemsToRemove = currentPhotoItems.filter {
            if case .photoItem = $0 { return true }
            return false
        }
        snapshot.deleteItems(photoItemsToRemove)

        // 새 사진 아이템 추가 (추가 버튼 뒤에)
        if let addButtonIndex = snapshot.itemIdentifiers(inSection: .photoPages).firstIndex(where: {
            if case .addPhotoButton = $0 { return true }
            return false
        }) {
            let addButtonItem = snapshot.itemIdentifiers(inSection: .photoPages)[addButtonIndex]
            snapshot.insertItems(photoIds.map { .photoItem($0) }, afterItem: addButtonItem)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func setupPhotoContextMenu(for cell: PhotoItemCell, photoId: String) {
        let menuItems = createPhotoMenuItems(for: photoId)
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

    private func createPhotoMenuItems(for photoId: String) -> [CircularMenuItem] {
        return [
            // 1. 사진 보기
            CircularMenuItem(name: "보기", image: UIImage(systemName: "eye")) { [weak self] in
                guard let self = self else { return }
                let image = self.imageQueue.sync {
                    self.photoImages[photoId]
                }
                if let image = image {
                    self.showImagePreview(image)
                }
            },
            // 2. 사진 저장
            CircularMenuItem(name: "저장", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] in
                guard let self = self else { return }
                let image = self.imageQueue.sync {
                    self.photoImages[photoId]
                }
                if let image = image {
                    self.saveImageToPhotoLibrary(image)
                }
            },
            // 3. 사진 삭제
            CircularMenuItem(name: "삭제", image: UIImage(systemName: "trash")) { [weak self] in
                self?.showDeletePhotoConfirmation(for: photoId)
            }
        ]
    }

    // MARK: - Quote Context Menu
    private func setupQuoteContextMenu(for cell: SavedQuoteCell, quote: String, pageNumber: Int?, date: Date) {
        let menuItems = createQuoteMenuItems(for: quote, pageNumber: pageNumber, date: date)
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

    private func createQuoteMenuItems(for quote: String, pageNumber: Int?, date: Date) -> [CircularMenuItem] {
        return [
            // 1. 공유
            CircularMenuItem(name: "공유", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] in
                self?.shareQuote(quote, pageNumber: pageNumber)
            },
            // 2. 수정
            CircularMenuItem(name: "수정", image: UIImage(systemName: "pencil")) { [weak self] in
                self?.editQuote(quote, pageNumber: pageNumber, date: date)
            },
            // 3. 삭제
            CircularMenuItem(name: "삭제", image: UIImage(systemName: "trash")) { [weak self] in
                self?.showDeleteQuoteConfirmation(for: quote, date: date)
            }
        ]
    }
    
    private func showImagePreview(_ image: UIImage) {
        let previewVC = UIViewController()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        
        previewVC.view = imageView
        previewVC.modalPresentationStyle = .fullScreen
        
        // 탭해서 닫기 제스처
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
            guard granted else {
                print("❌ Photo library permission denied")
                return
            }

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
            self?.deletePhoto(photoId)
        })

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))

        present(alert, animated: true)
    }

    private func deletePhoto(_ photoId: String) {
        guard let serviceFactory = serviceFactory else { return }

        let photoRepository = serviceFactory.createPhotoRepository()

        // photoId로 직접 삭제
        guard let objectId = try? ObjectId(string: photoId),
              let realm = try? Realm(),
              let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: objectId) else {
            print("❌ Photo not found")
            return
        }

        // 로컬 파일 삭제
        _ = ImageStorageManager.shared.deleteImage(atPath: photo.localImagePath)

        // 이미지 딕셔너리에서 제거
        imageQueue.async(flags: .barrier) { [weak self] in
            self?.photoImages.removeValue(forKey: photoId)
        }

        // Repository에서 삭제
        photoRepository.deletePhoto(photo)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    print("✅ Photo deleted successfully")
                    self?.loadPhotosAndUpdateUI()
                },
                onError: { error in
                    print("❌ Failed to delete photo: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Show All Quotes
    private func showAllQuotes() {
        guard let reactor = reactor, let serviceFactory = serviceFactory else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let quoteListCoordinator = QuoteListCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: QuoteListCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: serviceFactory
            )
        )

        addChildCoordinator(quoteListCoordinator)

        quoteListCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quotesUpdated:
                    print("✅ Quotes updated, refreshing...")
                    self?.loadQuotesAndUpdateUI()
                case .dismissed:
                    print("📝 Quote list dismissed")
                }
                self?.removeChildCoordinator(quoteListCoordinator)
            })
            .disposed(by: disposeBag)

        quoteListCoordinator.start()
    }

    // MARK: - Show All Photos
    private func showAllPhotos() {
        guard let reactor = reactor,
              let serviceFactory = serviceFactory else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let photoListCoordinator = PhotoListCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: PhotoListCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: serviceFactory,
                onAddPhotoTapped: { [weak self] in
                    self?.showPhotoCapture()
                }
            )
        )

        addChildCoordinator(photoListCoordinator)

        photoListCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .photosUpdated:
                    print("✅ Photos updated, refreshing...")
                    self?.loadPhotosAndUpdateUI()
                case .dismissed:
                    print("📷 Photo list dismissed")
                }
                self?.removeChildCoordinator(photoListCoordinator)
            })
            .disposed(by: disposeBag)

        photoListCoordinator.start()
    }

    // MARK: - Tag Input
    private func showTagInputAlert() {
        guard let reactor = reactor,
              let serviceFactory = serviceFactory else { return }

        let bookId = String(describing: reactor.currentState.book.id)
        let tagRepository = serviceFactory.createTagRepository()

        // 현재 책의 태그와 전체 태그 목록을 동시에 로드
        Observable.zip(
            tagRepository.getTags(for: bookId),
            tagRepository.getAllTags()
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onNext: { [weak self] currentTags, allTags in
            self?.presentTagEditView(currentTags: currentTags, allTags: allTags)
        }, onError: { error in
            print("Failed to load tags: \(error.localizedDescription)")
        })
        .disposed(by: disposeBag)
    }

    private func presentTagEditView(currentTags: [RealmTag], allTags: [RealmTag]) {
        let tagEditVC = TagEditViewController()

        let currentTagNames = currentTags.map { $0.tagName }
        let allUniqueTagNames = Array(Set(allTags.map { $0.tagName }))

        tagEditVC.configure(currentTags: currentTagNames, allTags: allUniqueTagNames)

        tagEditVC.onTagsSaved = { [weak self] tags in
            self?.saveTags(tags)
        }

        let navController = UINavigationController(rootViewController: tagEditVC)
        present(navController, animated: true)
    }

    private func saveTags(_ tags: [String]) {
        guard let reactor = reactor,
              let serviceFactory = serviceFactory else { return }

        let bookId = String(describing: reactor.currentState.book.id)
        let tagRepository = serviceFactory.createTagRepository()

        // 1. 기존 태그 삭제
        tagRepository.deleteTags(for: bookId)
            .flatMap { _ -> Observable<[RealmTag]> in
                guard !tags.isEmpty else {
                    return Observable.just([])
                }
                // 2. 새 태그 생성 및 저장
                let realmTags = tags.map { RealmTag(bookId: bookId, tagName: $0) }
                return tagRepository.saveTags(realmTags)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] savedTags in
                    if !savedTags.isEmpty {
                        print("Tags saved: \(savedTags.map { $0.tagName })")
                    }
                    self?.loadTagsAndUpdateUI()
                },
                onError: { error in
                    print("Failed to save tags: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func loadTagsAndUpdateUI() {
        guard let reactor = reactor,
              let service = service else { return }

        let bookId = String(describing: reactor.currentState.book.id)

        service.loadTags(bookId: bookId)
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] tags in
                self?.updateBookDetailWithTags(tags)
            })
            .disposed(by: disposeBag)
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

    private func updateBookDetailWithTags(_ tags: [RealmTag]) {
        guard let reactor = reactor,
              let bookDetail = reactor.currentState.bookDetail else { return }

        // BookDetail 업데이트 (tags는 String 배열)
        let tagNames = tags.map { $0.tagName }
        let updatedBookDetail = BookDetail(
            book: bookDetail.book,
            totalPages: bookDetail.totalPages,
            startDate: bookDetail.startDate,
            endDate: bookDetail.endDate,
            tags: tagNames
        )

        // 스냅샷 업데이트
        updateSnapshotWithUpdatedBookDetail(updatedBookDetail)
    }

    private func updateSnapshotWithUpdatedBookDetail(_ bookDetail: BookDetail) {
        var snapshot = dataSource.snapshot()

        // 기존 bookInfo 항목 업데이트
        let currentItems = snapshot.itemIdentifiers(inSection: .bookInfo)
        snapshot.deleteItems(currentItems)
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        dataSource.apply(snapshot, animatingDifferences: true)
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

        // 계속 보기 (취소 스타일 - 기본 액션)
        alert.addAction(UIAlertAction(title: "계속 보기", style: .cancel))

        // 삭제 (파괴적 스타일)
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteBook)
        })

        present(alert, animated: true)
    }
}

// MARK: - CameraViewController Delegate
extension BookDetailViewController: CameraViewControllerDelegate {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            self?.savePhoto(image)
        }
    }

    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        controller.dismiss(animated: true)
    }
}


// MARK: - UICollectionViewDelegate
extension BookDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .savedQuote(let quote, let pageNumber, let date):
            // 문장 수정
            editQuote(quote: quote, pageNumber: pageNumber, date: date)
        default:
            break
        }
    }

    private func editQuote(quote: String, pageNumber: Int?, date: Date) {
        guard let reactor = reactor,
              let _ = serviceFactory else { return }

        let bookId = String(describing: reactor.currentState.book.id)

        // Realm에서 해당 문장 찾기
        do {
            let realm = try Realm()
            let quotes = realm.objects(RealmQuote.self)
                .filter("bookId == %@ AND quote == %@ AND createdAt == %@", bookId, quote, date)

            guard let realmQuote = quotes.first else {
                print("❌ Quote not found")
                return
            }

            // QuoteEditViewController 표시
            showQuoteEdit(quoteId: String(describing: realmQuote.id), quote: quote, pageNumber: pageNumber)
        } catch {
            print("❌ Failed to find quote: \(error.localizedDescription)")
        }
    }

    private func showQuoteEdit(quoteId: String, quote: String, pageNumber: Int?) {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let quoteSaveVC = QuoteSaveViewController(bookId: bookId)
        quoteSaveVC.configureForEdit(quoteId: quoteId, quote: quote, pageNumber: pageNumber)

        if let serviceFactory = serviceFactory {
            let quoteRepository = serviceFactory.createQuoteRepository()
            quoteSaveVC.setQuoteRepository(quoteRepository)
        }

        // Rx event binding
        quoteSaveVC.events
            .subscribe(onNext: { [weak self] event in
                switch event {
                case .quoteSaved(let savedQuote):
                    quoteSaveVC.dismiss(animated: true) { [weak self] in
                        print("✅ Quote saved/updated: \(savedQuote)")
                        self?.loadQuotesAndUpdateUI()
                    }
                case .cancelled:
                    quoteSaveVC.dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)

        let navController = UINavigationController(rootViewController: quoteSaveVC)
        navController.modalPresentationStyle = .pageSheet

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(navController, animated: true)
    }

    // MARK: - Reading Statistics UI Update
    private func updateReadingStatisticsUI(_ statistics: ReadingStatistics?) {
        guard let dataSource = dataSource else { return }
        var snapshot = dataSource.snapshot()

        // readingRecords 섹션이 존재하는지 확인
        guard snapshot.sectionIdentifiers.contains(.readingRecords) else { return }

        // readingRecords 섹션의 기존 아이템 제거
        let existingItems = snapshot.itemIdentifiers(inSection: .readingRecords)
        if !existingItems.isEmpty {
            snapshot.deleteItems(existingItems)
        }

        if let statistics = statistics, !statistics.isEmpty {
            // 통계 데이터가 있으면 표시
            snapshot.appendItems([.readingStatistics(statistics)], toSection: .readingRecords)
        } else {
            // 통계 데이터가 없으면 추가 버튼 표시
            snapshot.appendItems([.addReadingRecordButton], toSection: .readingRecords)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func showReadingSessionList() {
        guard let coordinator = coordinator as? BookDetailCoordinator else {
            print("[BookDetailVC] ⚠️ Coordinator is nil, cannot show reading session list")
            return
        }
        coordinator.showReadingSessionList()
    }

    private func handlePeriodChange(_ period: ReadingStatisticsPeriod) {
        currentStatisticsPeriod = period

        // readingRecords 섹션의 셀 찾기
        let sectionIndex = Section.allCases.firstIndex(of: .readingRecords) ?? 0
        let indexPath = IndexPath(item: 0, section: sectionIndex)

        // 셀 업데이트
        if let cell = collectionView.cellForItem(at: indexPath) as? ReadingStatisticsCell {
            cell.updatePeriod(period)
        }
    }
}

// MARK: - Child Coordinator Management
extension BookDetailViewController {
    private func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    private func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    // MARK: - Quote Actions
    private func shareQuote(_ quote: String, pageNumber: Int?) {
        print("📤 [Share] Quote: \(quote), Page: \(pageNumber ?? 0)")
        // TODO: Implement share functionality
    }

    private func editQuote(_ quote: String, pageNumber: Int?, date: Date) {
        guard let reactor = reactor, let serviceFactory = serviceFactory else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        // 기존 문장을 수정하기 위해 QuoteSaveCoordinator 재사용
        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: QuoteSaveCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: serviceFactory,
                existingQuote: quote,
                existingPageNumber: pageNumber
            )
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quoteSaved(let updatedQuote):
                    print("✅ Quote updated: \(updatedQuote)")
                    self?.loadQuotesAndUpdateUI()
                case .cancelled:
                    print("📝 Quote edit cancelled")
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    private func showDeleteQuoteConfirmation(for quote: String, date: Date) {
        let alert = UIAlertController(
            title: "문장 삭제",
            message: "이 문장을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteQuote(quote, date: date)
        })

        present(alert, animated: true)
    }

    private func deleteQuote(_ quote: String, date: Date) {
        guard let reactor = reactor, let serviceFactory = serviceFactory else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let quoteRepository = serviceFactory.createQuoteRepository()

        // 문장 텍스트와 날짜로 해당 문장 찾아서 삭제
        quoteRepository.getQuotes(for: bookId)
            .observe(on: MainScheduler.instance)
            .take(1)
            .subscribe(onNext: { [weak self] quotes in
                // Realm Results를 Array로 변환하여 검색
                let quotesArray = Array(quotes)
                if let quoteToDelete = quotesArray.first(where: { $0.quote == quote && $0.createdAt == date }) {
                    quoteRepository.deleteQuote(quoteToDelete)
                        .observe(on: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] _ in
                            print("✅ Quote deleted successfully")
                            self?.loadQuotesAndUpdateUI()
                        }, onError: { error in
                            print("❌ Failed to delete quote: \(error)")
                        })
                        .disposed(by: self?.disposeBag ?? DisposeBag())
                }
            }, onError: { error in
                print("❌ Failed to fetch quotes for deletion: \(error)")
            })
            .disposed(by: disposeBag)
    }
}
