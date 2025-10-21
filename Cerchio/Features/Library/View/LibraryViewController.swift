//
//  LibraryViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import RealmSwift
import Kingfisher

final class LibraryViewController: BaseViewController<LibraryReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Book>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Book>

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!
    private let refreshControl = UIRefreshControl()

    // Book selection handler
    var bookSelectionHandler: ((Book) -> Void)?

    // Edit mode properties
    private var isEditMode = false
    private var selectedISBNs: Set<String> = []
    private var editButton: UIBarButtonItem!
    private var filterButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    private var selectAllButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!

    // Repository
    private var bookRepository: BookRepositoryProtocol?
    private var tagRepository: TagRepositoryProtocol?
    private var quoteRepository: QuoteRepositoryProtocol?
    private var photoRepository: PhotoRepositoryProtocol?

    // Temp storage for photo capture
    private var tempBookForPhoto: Book?

    nonisolated enum Section: CaseIterable {
        case book
    }

    override func setupUI() {
        super.setupUI()

        let layout = MasonryLayout()
        collectionView.collectionViewLayout = layout
        layout.delegate = self

        collectionView.register(LibraryCollectionViewCell.self)
        collectionView.backgroundColor = .clear
        collectionView.contentInset.bottom = 20
        collectionView.verticalScrollIndicatorInsets = .init(top: 0, left: 0, bottom: 20, right: 0)
        collectionView.allowsMultipleSelection = true
        collectionView.refreshControl = refreshControl
        view.addSubview(collectionView)

        collectionView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview(\.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.tintColor = .forestGreen

        // Remove navigation bar bottom line
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = nil // Remove bottom line
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        // 편집 모드였다면 기본 모드로 복귀
        if isEditMode {
            exitEditMode()
        }

        // 화면이 다시 나타날 때마다 데이터 새로고침
        reactor?.action.onNext(.loadBooks)
    }

    // MARK: - Public Methods
    func setEditButton(_ button: UIBarButtonItem) {
        editButton = button

        // Rx 바인딩
        editButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.editButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    func setFilterButton(_ button: UIBarButtonItem) {
        filterButton = button

        // Rx 바인딩
        filterButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.filterButtonTapped()
            })
            .disposed(by: disposeBag)

        // 편집 모드 버튼들 생성
        cancelButton = UIBarButtonItem(
            title: String(localized: .actionCancel),
            style: .plain,
            target: nil,
            action: nil
        )
        cancelButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.cancelButtonTapped()
            })
            .disposed(by: disposeBag)

        selectAllButton = UIBarButtonItem(
            title: String(localized: .actionSelectAll),
            style: .plain,
            target: nil,
            action: nil
        )
        selectAllButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.selectAllButtonTapped()
            })
            .disposed(by: disposeBag)

        deleteButton = UIBarButtonItem(
            title: String(localized: .actionDelete),
            style: .plain,
            target: nil,
            action: nil
        )
        deleteButton.tintColor = .systemRed
        deleteButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.deleteButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    func setBookRepository(_ repository: BookRepositoryProtocol) {
        bookRepository = repository
    }

    func setTagRepository(_ repository: TagRepositoryProtocol) {
        tagRepository = repository
    }

    func setQuoteRepository(_ repository: QuoteRepositoryProtocol) {
        quoteRepository = repository
    }

    func setPhotoRepository(_ repository: PhotoRepositoryProtocol) {
        photoRepository = repository
    }

    override func bind(reactor: LibraryReactor) {
        // Action
        Observable.just(LibraryReactor.Action.loadBooks)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Refresh Control
        refreshControl.rx.controlEvent(.valueChanged)
            .map { LibraryReactor.Action.loadBooks }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Collection View Selection - 일반 모드
        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == false }
            .subscribe(onNext: { [weak self] selectedBook in
                self?.bookSelectionHandler?(selectedBook)
            })
            .disposed(by: disposeBag)

        // Collection View Selection - 편집 모드
        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] selectedBook in
                guard let self = self else { return }

                // 이미 선택된 경우 deselect 처리 (다음 이벤트에서 처리됨)
                if self.selectedISBNs.contains(selectedBook.isbn) {
                    if let indexPath = self.dataSource.indexPath(for: selectedBook) {
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                    }
                } else {
                    // 새로 선택된 경우
                    self.selectedISBNs.insert(selectedBook.isbn)
                    if let indexPath = self.dataSource.indexPath(for: selectedBook) {
                        self.updateCellSelection(at: indexPath, isSelected: true)
                    }
                    self.updateNavigationBarForEditMode()
                }
            })
            .disposed(by: disposeBag)

        // Collection View Deselection - 편집 모드
        collectionView.rx.itemDeselected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] deselectedBook in
                guard let self = self else { return }

                self.selectedISBNs.remove(deselectedBook.isbn)
                if let indexPath = self.dataSource.indexPath(for: deselectedBook) {
                    self.updateCellSelection(at: indexPath, isSelected: false)
                }
                self.updateNavigationBarForEditMode()
            })
            .disposed(by: disposeBag)

        // State - Display Books (filtered or all)
        reactor.state
            .map { $0.displayBooks }
            .distinctUntilChanged { oldBooks, newBooks in
                // Compare by book ISBNs, count, and isFavorite to detect changes
                guard let oldBooks = oldBooks, let newBooks = newBooks else {
                    return oldBooks == nil && newBooks == nil
                }
                guard oldBooks.count == newBooks.count else { return false }

                // ISBN 순서 비교
                let oldISBNs = oldBooks.map { $0.isbn }
                let newISBNs = newBooks.map { $0.isbn }
                guard oldISBNs == newISBNs else { return false }

                // isFavorite 상태 비교 (ISBN 순서가 같을 때만)
                for (oldBook, newBook) in zip(oldBooks, newBooks) {
                    if oldBook.isFavorite != newBook.isFavorite {
                        return false
                    }
                }

                return true
            }
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] books in
                self?.updateData(books: books)
            })
            .disposed(by: disposeBag)

        // State - Active Filters (for navigation title)
        reactor.state
            .map { ($0.activeFilters, $0.isFavoriteFilterEnabled) }
            .distinctUntilChanged { lhs, rhs in
                let filtersEqual = lhs.0 == rhs.0
                let favoriteEqual = lhs.1 == rhs.1
                return filtersEqual && favoriteEqual
            }
            .asDriver(onErrorJustReturn: ([], false))
            .drive(onNext: { [weak self] filters, isFavoriteEnabled in
                self?.updateNavigationTitle(with: filters, isFavoriteEnabled: isFavoriteEnabled)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isLoading in
                self?.handleLoadingState(isLoading)
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            })
            .disposed(by: disposeBag)

        // Cell will display - 편집 모드에서 선택된 셀 border 복원
        collectionView.rx.willDisplayCell(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] (cell, book, indexPath) in
                guard let self = self else { return }

                let isSelected = self.selectedISBNs.contains(book.isbn)
                if isSelected {
                    cell.layer.borderWidth = 2.0
                    cell.layer.borderColor = UIColor.forestGreen.cgColor
                    cell.layer.cornerRadius = 8.0
                }
            })
            .disposed(by: disposeBag)
    }

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(LibraryCollectionViewCell.self, for: indexPath)

            // indexPath.item이 짝수면 왼쪽 컬럼, 홀수면 오른쪽 컬럼
            let isLeftColumn = indexPath.item % 2 == 0
            cell.configure(with: item, isLeftColumn: isLeftColumn)

            self?.setupLongPressGesture(for: cell, with: item, at: indexPath)
            return cell
        }

        collectionView.dataSource = dataSource

        // 기본 섹션 설정
        setupInitialSnapshot()
    }

    private func setupInitialSnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 뷰의 레이아웃이 완료된 후 컬렉션 뷰 레이아웃 업데이트
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupLongPressGesture(for cell: LibraryCollectionViewCell, with book: Book, at indexPath: IndexPath) {
        // 편집 모드에서는 롱 프레스 제스처 비활성화
        guard !isEditMode else {
            // 편집 모드에서는 기존 롱 프레스 제스처 제거
            removeLongPressGesture(from: cell)
            return
        }

        // 기존 롱 프레스 제스처 제거 (셀 재사용 시 중복 방지)
        removeLongPressGesture(from: cell)

        // 셀이 화면에 완전히 표시된 후에 제스처 추가
        DispatchQueue.main.async { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }

            let menuItems = self.createMenuItems(for: book, at: indexPath)

            // 하이라이트 효과 설정 (필요시 커스터마이즈 가능)
            // 예시:
            // - .withContextualRotation() - 기본값: 1.2배 확대 + 화면 위치에 따른 회전
            // - ViewHighlightConfiguration(effect: .scale(1.5), ...) - 1.5배 확대만
            // - ViewHighlightConfiguration(effect: .combined([.scale(1.3), .rotation(degrees: 10)]), ...) - 1.3배 확대 + 10도 회전
            let highlightConfig = ViewHighlightConfiguration.withContextualRotation()

            CircularMenuManager.shared.addLongPressMenu(
                to: cell,
                targetView: cell,
                items: menuItems,
                presentingViewController: self,
                minimumPressDuration: LibraryConstants.Gesture.minimumPressDuration,
                highlightConfiguration: highlightConfig
            )
        }
    }

    private func removeLongPressGesture(from cell: LibraryCollectionViewCell) {
        // 롱 프레스 제스처만 선택적으로 제거
        if let gestureRecognizers = cell.gestureRecognizers {
            for gesture in gestureRecognizers {
                if gesture is UILongPressGestureRecognizer {
                    cell.removeGestureRecognizer(gesture)
                }
            }
        }
    }
    
    private func createMenuItems(for book: Book, at indexPath: IndexPath) -> [CircularMenuItem] {
        // 최신 즐겨찾기 상태를 실시간으로 가져오기
        let isFavorite = getCurrentFavoriteState(for: book)

        let menuItems: [CircularMenuItem] = [
            // 1. 사진 찍기
            CircularMenuItem(name: String(localized: .circularMenuLibraryTakePhoto), image: UIImage(systemName: "camera")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.capturePhoto(for: book)
            },
            // 2. 문장 저장
            CircularMenuItem(name: String(localized: .circularMenuBookDetailSaveQuote), image: UIImage(systemName: "quote.bubble")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.saveQuote(for: book)
            },
            // 3. 즐겨찾기
            CircularMenuItem(name: isFavorite ? String(localized: .circularMenuBookDetailRemoveFavorite) : String(localized: .circularMenuBookDetailAddFavorite), image: UIImage(systemName: isFavorite ? "heart.fill" : "heart")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.toggleFavorite(book)
            },
            // 4. 삭제
            CircularMenuItem(name: String(localized: .circularMenuCommonDelete), image: UIImage(systemName: "trash")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.deleteBook(book, at: indexPath)
            },
            // 5. 수정 (도서 정보 수정)
            CircularMenuItem(name: String(localized: .circularMenuCommonEdit), image: UIImage(systemName: "pencil")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.editBookInfo(for: book)
            }
        ]

        return menuItems
    }

    private func getCurrentFavoriteState(for book: Book) -> Bool {
        // Reactor의 최신 상태에서 해당 책의 즐겨찾기 상태를 가져옴
        guard let reactor = reactor,
              let books = reactor.currentState.displayBooks,
              let currentBook = books.first(where: { $0.isbn == book.isbn }) else {
            return book.isFavorite
        }
        return currentBook.isFavorite
    }

    // MARK: - Menu Actions

    // 1. 사진 찍기
    private func capturePhoto(for book: Book) {
        // Book 정보를 저장해두기 위해 임시로 저장
        self.tempBookForPhoto = book

        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false

        self.present(imagePicker, animated: true)
    }

    // 2. 문장 저장
    private func saveQuote(for book: Book) {
        showQuoteInputAlert(for: book)
    }

    // 3. 즐겨찾기 토글
    private func toggleFavorite(_ book: Book) {
        guard let bookRepository = bookRepository else { return }

        // book.id는 이미 ObjectId의 문자열 표현이므로 그대로 사용
        let bookId = book.id

        bookRepository.toggleFavorite(bookId: bookId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                print(" Favorite toggled for '\(book.cleanTitle)': \(isFavorite)")
                // 데이터 새로고침
                self?.reactor?.action.onNext(.loadBooks)
            }, onError: { error in
                print(" Failed to toggle favorite: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    // 5. 도서 정보 수정
    private func editBookInfo(for book: Book) {
        showReadingInfoEdit(for: book)
    }

    // 4. 삭제
    private func deleteBook(_ book: Book, at indexPath: IndexPath) {
        showDeleteConfirmation(for: book, at: indexPath)
    }

    private func showDeleteConfirmation(for book: Book, at indexPath: IndexPath) {
        let messageFormat = NSLocalizedString("alert.library.delete_book_single.message_format", comment: "")
        let message = String(format: messageFormat, book.title)

        let alert = UIAlertController(
            title: String(localized: .alertDeleteBookTitle),
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            guard let self = self, let bookRepository = self.bookRepository else { return }

            bookRepository.deleteBooksByISBNs([book.isbn])
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    print(" Book deleted: \(book.cleanTitle)")
                    // 데이터 새로고침
                    self?.reactor?.action.onNext(.loadBooks)
                }, onError: { error in
                    print(" Failed to delete book: \(error.localizedDescription)")
                })
                .disposed(by: self.disposeBag)
        })

        present(alert, animated: true)
    }

    private func updateData(books: [Book]?) {
        guard let dataSource = dataSource, let books = books else { return }

        // 항상 새 스냅샷 생성
        // Book이 Hashable이므로 DiffableDataSource가 자동으로 변경 감지
        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        snapshot.appendItems(books, toSection: .book)

        // animatingDifferences: true로 부드러운 애니메이션 적용
        // DiffableDataSource가 Book의 해시값 변경을 감지하여 해당 셀만 업데이트
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func handleLoadingState(_ isLoading: Bool) {
        if isLoading {
            // TODO: 로딩 인디케이터 표시
            print("Loading books...")
        } else {
            // TODO: 로딩 인디케이터 숨기기
            print("Loading completed")
        }
    }

    // MARK: - Navigation Title Update
    private func updateNavigationTitle(with filters: [String], isFavoriteEnabled: Bool) {
        guard let tabBarController = tabBarController else { return }

        var titleComponents: [String] = []

        // 즐겨찾기 필터가 활성화된 경우
        if isFavoriteEnabled {
            titleComponents.append("♥")
        }

        // 태그 필터가 활성화된 경우
        if !filters.isEmpty {
            let tagText = filters.map { "#\($0)" }.joined(separator: " ")
            titleComponents.append(tagText)
        }

        if titleComponents.isEmpty {
            tabBarController.navigationItem.title = String(localized: .tabLibrary)
        } else {
            tabBarController.navigationItem.title = titleComponents.joined(separator: " ")
        }
    }

    // MARK: - Edit Mode Actions
    private func filterButtonTapped() {
        guard let tagRepository = tagRepository else { return }

        // 모든 태그 로드
        tagRepository.getAllTags()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] allTags in
                guard let self = self else { return }

                // 중복 제거하여 고유한 태그 이름 목록 생성
                let uniqueTags = Array(Set(allTags.map { $0.tagName })).sorted()

                // 태그가 없어도 즐겨찾기 필터링을 위해 필터 화면 표시
                self.presentTagFilterView(with: uniqueTags)
            }, onError: { error in
                print("Failed to load tags: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private func presentTagFilterView(with tags: [String]) {
        let filterVC = TagFilterViewController()
        let currentFilters = reactor?.currentState.activeFilters ?? []
        let isFavoriteEnabled = reactor?.currentState.isFavoriteFilterEnabled ?? false
        filterVC.configure(with: tags, selectedTags: currentFilters, isFavoriteEnabled: isFavoriteEnabled)

        filterVC.onFilterApplied = { [weak self] selectedTags, favoriteOnly in
            guard let self = self, let reactor = self.reactor else { return }

            if selectedTags.isEmpty && !favoriteOnly {
                // 필터 초기화
                reactor.action.onNext(.clearFilters)
            } else {
                // 필터 적용
                reactor.action.onNext(.applyTagFilters(selectedTags, favoriteOnly: favoriteOnly))
            }
        }

        let navController = UINavigationController(rootViewController: filterVC)
        present(navController, animated: true)
    }

    private func editButtonTapped() {
        // 편집 모드 진입
        enterEditMode()
    }

    private func enterEditMode() {
        // 필터가 활성화되어 있으면 먼저 해제
        if let reactor = reactor,
           (!reactor.currentState.activeFilters.isEmpty || reactor.currentState.isFavoriteFilterEnabled) {
            reactor.action.onNext(.clearFilters)
        }

        isEditMode = true
        selectedISBNs.removeAll()

        // 햅틱 피드백
        HapticFeedbackManager.shared.impact()

        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()
    }

    private func exitEditMode() {
        isEditMode = false
        selectedISBNs.removeAll()

        // 햅틱 피드백
        HapticFeedbackManager.shared.impact()

        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()

        // 모든 셀의 선택 상태 및 border 해제
        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: true)
            updateCellSelection(at: indexPath, isSelected: false)
        }

        // 모든 가시 셀의 border 제거 (선택되지 않았지만 border가 있을 수 있는 셀 포함)
        for cell in collectionView.visibleCells {
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }

    private func updateNavigationBarForEditMode() {
        guard let tabBarController = tabBarController else { return }

        if isEditMode {
            // 편집 모드
            if selectedISBNs.isEmpty {
                // 선택된 책이 없으면: [취소] [전체 선택]
                tabBarController.navigationItem.leftBarButtonItem = cancelButton
                tabBarController.navigationItem.rightBarButtonItems = [selectAllButton]
            } else {
                // 선택된 책이 있으면: [취소] [삭제]
                tabBarController.navigationItem.leftBarButtonItem = cancelButton
                tabBarController.navigationItem.rightBarButtonItems = [deleteButton]
            }
        } else {
            // 일반 모드: [편집] [필터]
            tabBarController.navigationItem.leftBarButtonItem = nil
            tabBarController.navigationItem.rightBarButtonItems = [editButton, filterButton]
        }
    }

    private func cancelButtonTapped() {
        // 편집 모드 종료
        exitEditMode()
    }

    private func selectAllButtonTapped() {
        guard let reactor = reactor,
              let books = reactor.currentState.displayBooks else { return }

        // 모든 책 선택
        for (index, book) in books.enumerated() {
            selectedISBNs.insert(book.isbn)
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            updateCellSelection(at: indexPath, isSelected: true)
        }

        updateNavigationBarForEditMode()
    }

    private func deleteButtonTapped() {
        deleteSelectedBooks()
    }

    private func updateCollectionViewForEditMode() {
        // 편집 모드에 따라 컬렉션 뷰 상태 업데이트
        collectionView.reloadData()
    }

    private func updateCellSelection(at indexPath: IndexPath, isSelected: Bool) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? LibraryCollectionViewCell else { return }

        if isSelected {
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColor.forestGreen.cgColor
            cell.layer.cornerRadius = 8.0
        } else {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }

    private func deleteSelectedBooks() {
        let messageFormat = NSLocalizedString("alert.library.delete_books_multiple.message_format", comment: "")
        let message = String(format: messageFormat, selectedISBNs.count)

        let alert = UIAlertController(
            title: String(localized: .actionDelete),
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            self?.performDeletion()
        })

        present(alert, animated: true)
    }

    private func performDeletion() {
        guard let reactor = reactor,
              let bookRepository = bookRepository else { return }

        // Copy selected ISBNs and current filters before clearing
        let isbnsToDelete = Array(selectedISBNs)
        let currentFilters = reactor.currentState.activeFilters
        let isFavoriteEnabled = reactor.currentState.isFavoriteFilterEnabled

        guard !isbnsToDelete.isEmpty else { return }

        // 먼저 편집 모드를 종료하고 UI 업데이트 (무효화된 객체 참조 방지)
        exitEditMode()

        // Use ISBN-based deletion to avoid working with invalidated objects
        bookRepository.deleteBooksByISBNs(isbnsToDelete)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let self = self, let reactor = self.reactor else { return }

                    // 데이터 새로고침
                    reactor.action.onNext(.loadBooks)

                    // 필터가 활성화되어 있었다면 다시 적용
                    if !currentFilters.isEmpty || isFavoriteEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            reactor.action.onNext(.applyTagFilters(currentFilters, favoriteOnly: isFavoriteEnabled))
                        }
                    }
                },
                onError: { [weak self] error in
                    print("Failed to delete books: \(error.localizedDescription)")
                    self?.showDeleteErrorAlert()
                    // 삭제 실패 시 데이터 새로고침하여 일관성 유지
                    reactor.action.onNext(.loadBooks)
                }
            )
            .disposed(by: disposeBag)
    }

    private func showDeleteErrorAlert() {
        let alert = UIAlertController(
            title: String(localized: .alertLibraryDeleteFailedTitle),
            message: String(localized: .alertLibraryDeleteFailedMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .actionConfirm), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Quote Input
extension LibraryViewController {
    private func showQuoteInputAlert(for book: Book) {
        let alert = UIAlertController(
            title: String(localized: .quoteSaveTitle),
            message: String(localized: .quoteSaveMessage),
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = String(localized: .quoteSavePlaceholderText)
        }

        alert.addTextField { textField in
            textField.placeholder = String(localized: .quoteSavePageLabel)
            textField.keyboardType = .numberPad
        }

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .actionSave), style: .default) { [weak self, weak alert] _ in
            guard let quote = alert?.textFields?[0].text, !quote.isEmpty else { return }
            let pageNumberText = alert?.textFields?[1].text
            let pageNumber = pageNumberText.flatMap { Int($0) }

            self?.saveQuoteToRealm(quote: quote, pageNumber: pageNumber, for: book)
        })

        present(alert, animated: true)
    }

    private func saveQuoteToRealm(quote: String, pageNumber: Int?, for book: Book) {
        guard let quoteRepository = quoteRepository else {
            print(" QuoteRepository not available")
            return
        }

        let bookId = String(describing: book.id)

        let realmQuote = RealmQuote(
            bookId: bookId,
            quote: quote,
            pageNumber: pageNumber
        )

        quoteRepository.saveQuote(realmQuote)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] savedQuote in
                    guard self != nil else { return }
                    print(" Quote saved: \(quote), page: \(pageNumber ?? 0) for book: \(book.cleanTitle)")
                    // 필요시 UI 업데이트
                },
                onError: { error in
                    print(" Failed to save quote: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }
}

// MARK: - Photo Capture
extension LibraryViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage,
              let book = tempBookForPhoto else { return }

        savePhotoToRealm(image: image, for: book)
        tempBookForPhoto = nil
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        tempBookForPhoto = nil
    }

    private func savePhotoToRealm(image: UIImage, for book: Book) {
        guard let photoRepository = photoRepository else {
            print(" PhotoRepository not available")
            return
        }

        let bookId = String(describing: book.id)

        // 이미지를 로컬에 저장
        let imageName = ImageStorageManager.shared.generateUniqueImageName(for: bookId)
        guard let localPath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
            print(" Failed to save image locally")
            return
        }

        // Realm에 사진 메타데이터 저장
        let realmPhoto = RealmPhoto(
            bookId: bookId,
            localImagePath: localPath
        )

        photoRepository.savePhoto(realmPhoto)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] savedPhoto in
                    guard self != nil else { return }
                    print(" Photo saved for book: \(book.cleanTitle)")
                    // 필요시 UI 업데이트
                },
                onError: { [weak self] error in
                    guard self != nil else { return }
                    print(" Failed to save photo: \(error.localizedDescription)")
                    // 저장 실패 시 로컬 이미지 삭제
                    _ = ImageStorageManager.shared.deleteImage(atPath: localPath)
                }
            )
            .disposed(by: disposeBag)
    }
}

// MARK: - Reading Info Edit
extension LibraryViewController {
    private func showReadingInfoEdit(for book: Book) {
        let readingInfoEditVC = ReadingInfoEditViewController()
        readingInfoEditVC.configure(
            totalPages: book.totalPages ?? 0,
            startDate: book.startDate,
            endDate: book.endDate
        )
        readingInfoEditVC.onSaved = { [weak self] totalPages, startDate, endDate in
            self?.updateBookReadingInfo(for: book, totalPages: totalPages, startDate: startDate, endDate: endDate)
        }

        let navController = UINavigationController(rootViewController: readingInfoEditVC)
        present(navController, animated: true)
    }

    private func updateBookReadingInfo(for book: Book, totalPages: Int, startDate: Date?, endDate: Date?) {
        guard let bookRepository = bookRepository else { return }

        let updatedBook = Book(
            id: book.id,
            title: book.title,
            cleanTitle: book.cleanTitle,
            link: book.link,
            image: book.image,
            author: book.author,
            isbn: book.isbn,
            publisher: book.publisher,
            bookDescription: book.bookDescription,
            cleanDescription: book.cleanDescription,
            pubdate: book.pubdate,
            discount: book.discount,
            formattedPubDate: book.formattedPubDate,
            formattedPrice: book.formattedPrice,
            priceAsInt: book.priceAsInt,
            createAt: book.createAt,
            genre: book.genre,
            totalPages: totalPages,
            startDate: startDate,
            endDate: endDate,
            isFavorite: book.isFavorite,
            dateAdded: book.dateAdded,
            dateRead: book.dateRead,
            readingStatus: book.readingStatus,
            category: book.category,
            rating: book.rating
        )

        bookRepository.saveBookStruct(updatedBook)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                print(" Book reading info updated")
                self?.reactor?.action.onNext(.loadBooks)
            }, onError: { error in
                print(" Failed to update book reading info: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
}

extension LibraryViewController: MasonryLayoutProtocol {
    func collectionView(_ collectionView: UICollectionView, heightAtIndexPath indexPath: IndexPath) -> CGFloat {
        guard let reactor = reactor else { return LibraryConstants.HeightCalculation.defaultHeight }

        let books = reactor.currentState.displayBooks
        guard let books = books, indexPath.item < books.count else { return LibraryConstants.HeightCalculation.defaultHeight }

        let book = books[indexPath.item]

        // 셀 너비 계산 (2 컬럼 레이아웃)
        let numberOfColumns: CGFloat = CGFloat(MasonryConstants.Layout.numberOfColumns)
        let contentWidth = collectionView.bounds.width
        let columnWidth = contentWidth / numberOfColumns

        // MasonryLayout에서 적용하는 패딩 (좌우 대칭)
        let isLeftColumn = indexPath.item % 2 == 0
        let masonryLeftPadding: CGFloat = isLeftColumn ? 8 : 2  // MasonryLayout의 leftInset과 동일
        let masonryRightPadding: CGFloat = isLeftColumn ? 2 : 8  // MasonryLayout의 rightInset과 동일

        // 셀 내부 cellInset
        let cellInset = LibraryConstants.Layout.cellInset

        // 실제 콘텐츠 사용 가능 너비
        let availableWidth = columnWidth - masonryLeftPadding - masonryRightPadding - (cellInset * 2)

        // 백그라운드 뷰 높이 (정사각형)
        let backgroundHeight = availableWidth

        // 타이틀 레이블 높이 동적 계산
        let titleHeight = calculateLabelHeight(
            text: book.cleanTitle,
            font: .custom(weight: .semiBold, size: LibraryConstants.Typography.titleFontSize),
            width: availableWidth
        )

        // 저자 레이블 높이 동적 계산
        let authorHeight = calculateLabelHeight(
            text: book.author,
            font: .custom(weight: .regular, size: LibraryConstants.Typography.authorFontSize),
            width: availableWidth
        ) * 2

        // 총 높이 = 백그라운드 + 간격 + 타이틀 + 간격 + 저자 + 하단 여백
        let totalHeight = backgroundHeight
            + LibraryConstants.Layout.stackOffset
            + titleHeight
            + LibraryConstants.Layout.stackOffset
            + authorHeight
            + LibraryConstants.Layout.stackOffset

        return totalHeight
    }

    private func calculateLabelHeight(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let label = UILabel()
        label.font = font
        label.text = text
        label.numberOfLines = 0 // 무제한 줄 수

        let size = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return ceil(size.height)
    }
}
