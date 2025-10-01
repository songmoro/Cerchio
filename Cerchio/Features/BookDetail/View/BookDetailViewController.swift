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
    
    // MARK: - Section & Item Types
    nonisolated enum Section: CaseIterable {
        case bookInfo
        case savedQuotes
        case photoPages
    }
    
    nonisolated enum Item: Hashable {
        case bookInfo(BookDetail)
        case savedQuote(String, Int?, Date) // 문장 텍스트, 페이지, 저장 날짜
        case addQuoteButton // 문장 추가 버튼
        case photoItem(UIImage) // 개별 사진
        case addPhotoButton // 사진 추가 버튼
        case photoLoadingIndicator // 사진 로딩 인디케이터

        func hash(into hasher: inout Hasher) {
            switch self {
            case .bookInfo(let detail):
                hasher.combine("bookInfo")
                hasher.combine(detail)
            case .savedQuote(let quote, let page, let date):
                hasher.combine("savedQuote")
                hasher.combine(quote)
                hasher.combine(page)
                hasher.combine(date)
            case .addQuoteButton:
                hasher.combine("addQuoteButton")
            case .photoItem(let image):
                hasher.combine("photoItem")
                hasher.combine(image.pngData())
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
            case (.savedQuote(let lq, let lp, let ld), .savedQuote(let rq, let rp, let rd)):
                return lq == rq && lp == rp && ld == rd
            case (.addQuoteButton, .addQuoteButton):
                return true
            case (.photoItem(let l), .photoItem(let r)):
                return l.pngData() == r.pngData()
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
                self?.reactor?.action.onNext(.deleteBook)
            })
            .disposed(by: disposeBag)
    }

    func setServiceFactory(_ factory: ServiceFactory) {
        serviceFactory = factory
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
        collectionView.register(SavedQuoteCell.self)
        collectionView.register(AddQuoteButtonCell.self)
        collectionView.register(PhotoItemCell.self)
        collectionView.register(AddPhotoCell.self)
        collectionView.register(PhotoLoadingCell.self)

        // 헤더 등록
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

            case .savedQuote(let quote, let pageNumber, let date):
                let cell: SavedQuoteCell = collectionView.dequeueReusableCell(SavedQuoteCell.self, for: indexPath)
                cell.configure(with: quote, pageNumber: pageNumber, date: date)
                return cell

            case .addQuoteButton:
                let cell: AddQuoteButtonCell = collectionView.dequeueReusableCell(AddQuoteButtonCell.self, for: indexPath)
                cell.onAddQuoteTapped = { [weak self] in
                    self?.showQuoteEntry()
                }
                return cell

            case .photoItem(let image):
                let cell: PhotoItemCell = collectionView.dequeueReusableCell(PhotoItemCell.self, for: indexPath)
                cell.configure(with: image)
                cell.onPhotoTapped = { [weak self] image in
                    self?.showImagePreview(image)
                }

                // 컨텍스트 메뉴 설정
                self?.setupPhotoContextMenu(for: cell, with: image)

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
        snapshot.appendSections([.bookInfo, .savedQuotes, .photoPages])

        // 책 정보
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        // 저장한 문장 (기본 빈 데이터, 실제 데이터는 별도 로드)
        snapshot.appendItems([.savedQuote("", nil, Date())], toSection: .savedQuotes)

        // 찍은 사진 (기본 빈 데이터, 실제 데이터는 별도 로드)
        snapshot.appendItems([.addPhotoButton], toSection: .photoPages)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Navigation Methods
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
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)
        
        // 로컬 저장
        let imageName = ImageStorageManager.shared.generateUniqueImageName(for: bookId)
        guard let localPath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
            print("❌ Failed to save image locally")
            return
        }
        
        // Realm 저장
        let realmPhoto = RealmPhoto(
            bookId: bookId,
            localImagePath: localPath
        )
        
        if savePhotoToRealm(realmPhoto) {
            print("✅ Photo saved successfully")
            loadPhotosAndUpdateUI()
        } else {
            print("❌ Failed to save photo to Realm")
            ImageStorageManager.shared.deleteImage(atPath: localPath)
        }
    }
    
    private func savePhotoToRealm(_ realmPhoto: RealmPhoto) -> Bool {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(realmPhoto)
            }
            return true
        } catch {
            return false
        }
    }
    
    private func loadPhotosAndUpdateUI() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)
        
        do {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            let photoArray = Array(photos)
            
            updateSnapshotWithPhotos(bookDetail: reactor.currentState.bookDetail, photos: photoArray)
        } catch {
            print("❌ Failed to load photos: \(error.localizedDescription)")
        }
    }
    
    private func loadQuotesAndUpdateUI() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        do {
            let realm = try Realm()
            let quotes = realm.objects(RealmQuote.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)
            let quoteArray = Array(quotes)
            
            updateSnapshotWithAllData(
                bookDetail: reactor.currentState.bookDetail,
                quotes: quoteArray,
                photos: nil // 포토는 별도로 로드
            )
        } catch {
            print("❌ Failed to load quotes: \(error.localizedDescription)")
        }
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
        snapshot.appendSections([.bookInfo, .savedQuotes, .photoPages])

        // 책 정보
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

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

    private func loadPhotosAsync(photos: [RealmPhoto]) {
        // 메인 스레드에서 Realm 객체 정렬 및 경로 추출
        let sortedPhotos = photos.sorted { $0.createdAt > $1.createdAt }
        let imagePaths = sortedPhotos.map { $0.localImagePath }

        // 백그라운드에서 이미지만 로드
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let images = imagePaths.compactMap { ImageStorageManager.shared.loadImage(fromPath: $0) }

            DispatchQueue.main.async {
                guard let self = self else { return }

                var snapshot = self.dataSource.snapshot()
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
                    snapshot.insertItems(images.map { .photoItem($0) }, afterItem: addButtonItem)
                }

                self.dataSource.apply(snapshot, animatingDifferences: true)
            }
        }
    }

    private func loadPhotosFromRealm() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        do {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            let sortedPhotos = photos.sorted(byKeyPath: "createdAt", ascending: false)
            let photoArray = Array(sortedPhotos)

            // 메인 스레드에서 이미지 경로 추출
            let imagePaths = photoArray.map { $0.localImagePath }

            // 이미지 로드만 백그라운드에서 처리
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let images = imagePaths.compactMap { ImageStorageManager.shared.loadImage(fromPath: $0) }

                DispatchQueue.main.async {
                    guard let self = self else { return }

                    var snapshot = self.dataSource.snapshot()
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
                        snapshot.insertItems(images.map { .photoItem($0) }, afterItem: addButtonItem)
                    }

                    self.dataSource.apply(snapshot, animatingDifferences: true)
                }
            }
        } catch {
            print("❌ Failed to load photos from Realm: \(error.localizedDescription)")
        }
    }

    private func setupPhotoContextMenu(for cell: PhotoItemCell, with image: UIImage) {
        let menuItems = createPhotoMenuItems(for: image)
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

    private func createPhotoMenuItems(for image: UIImage) -> [CircularMenuItem] {
        return [
            // 1. 사진 보기
            CircularMenuItem(name: "보기", image: UIImage(systemName: "eye")) { [weak self] in
                self?.showImagePreview(image)
            },
            // 2. 사진 저장
            CircularMenuItem(name: "저장", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] in
                self?.saveImageToPhotoLibrary(image)
            },
            // 3. 사진 삭제
            CircularMenuItem(name: "삭제", image: UIImage(systemName: "trash")) { [weak self] in
                self?.showDeletePhotoConfirmation(for: image)
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
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
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
    
    private func showDeletePhotoConfirmation(for image: UIImage) {
        let alert = UIAlertController(
            title: String(localized: .photoDeleteConfirmationTitle),
            message: String(localized: .photoDeleteConfirmationMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            self?.deletePhoto(image)
        })

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))

        present(alert, animated: true)
    }
    
    private func deletePhoto(_ image: UIImage) {
        guard let reactor = reactor,
              let serviceFactory = serviceFactory else { return }

        let bookId = String(describing: reactor.currentState.book.id)
        let photoRepository = serviceFactory.createPhotoRepository()

        // Get all photos for this book
        photoRepository.getPhotos(for: bookId)
            .flatMap { photos -> Observable<RealmPhoto?> in
                // Find photo to delete by comparing image data
                for photo in photos {
                    if let loadedImage = ImageStorageManager.shared.loadImage(fromPath: photo.localImagePath),
                       loadedImage.pngData() == image.pngData() {
                        return Observable.just(photo)
                    }
                }
                return Observable.just(nil)
            }
            .flatMap { [weak self] photoToDelete -> Observable<Void> in
                guard let photoToDelete = photoToDelete else {
                    return Observable.error(NSError(domain: "PhotoNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Photo not found"]))
                }

                // Delete local file first
                ImageStorageManager.shared.deleteImage(atPath: photoToDelete.localImagePath)

                // Delete from repository
                return photoRepository.deletePhoto(photoToDelete)
            }
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
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let photoListCoordinator = PhotoListCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: PhotoListCoordinator.Dependencies(
                bookId: bookId,
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
              let serviceFactory = serviceFactory else { return }

        let bookId = String(describing: reactor.currentState.book.id)

        let tagRepository = serviceFactory.createTagRepository()
        tagRepository.getTags(for: bookId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] tags in
                self?.updateBookDetailWithTags(tags)
            }, onError: { error in
                print("❌ Failed to load tags: \(error.localizedDescription)")
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
              var bookDetail = reactor.currentState.bookDetail else { return }

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

// MARK: - QuoteSaveViewControllerDelegate
extension BookDetailViewController: QuoteSaveViewControllerDelegate {
    func quoteSaveViewController(_ controller: QuoteSaveViewController, didSaveQuote quote: String) {
        controller.dismiss(animated: true) { [weak self] in
            print("✅ Quote saved/updated: \(quote)")
            self?.loadQuotesAndUpdateUI()
        }
    }

    func quoteSaveViewControllerDidCancel(_ controller: QuoteSaveViewController) {
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
              let serviceFactory = serviceFactory else { return }

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

        quoteSaveVC.delegate = self

        let navController = UINavigationController(rootViewController: quoteSaveVC)
        navController.modalPresentationStyle = .pageSheet

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(navController, animated: true)
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
}
