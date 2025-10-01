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

final class LibraryViewController: BaseViewController<LibraryReactor>, UICollectionViewDelegate {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Book>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Book>

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!

    // Book selection handler
    var bookSelectionHandler: ((Book) -> Void)?

    // Edit mode properties
    private var isEditMode = false
    private var selectedISBNs: Set<String> = []
    private var editButton: UIBarButtonItem!
    private var filterButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!

    // Repository
    private var bookRepository: BookRepositoryProtocol?
    private var tagRepository: TagRepositoryProtocol?

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
        collectionView.delegate = self
        view.addSubview(collectionView)

        collectionView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview(\.safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }

        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 화면이 다시 나타날 때마다 데이터 새로고침
        reactor?.action.onNext(.loadBooks)
    }

    // MARK: - Public Methods
    func setEditButton(_ button: UIBarButtonItem) {
        editButton = button
    }

    func setFilterButton(_ button: UIBarButtonItem) {
        filterButton = button

        // 취소 버튼 생성 (편집 모드에서 사용)
        cancelButton = UIBarButtonItem(
            title: String(localized: .actionCancel),
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }

    func setBookRepository(_ repository: BookRepositoryProtocol) {
        bookRepository = repository
    }

    func setTagRepository(_ repository: TagRepositoryProtocol) {
        tagRepository = repository
    }

    override func bind(reactor: LibraryReactor) {
        // Action
        Observable.just(LibraryReactor.Action.loadBooks)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Collection View Selection
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self,
                      let reactor = self.reactor else { return }

                let books = reactor.currentState.displayBooks
                guard let books, indexPath.item < books.count else { return }

                let selectedBook = books[indexPath.item]

                if self.isEditMode {
                    // 편집 모드에서는 선택/해제 토글
                    if self.selectedISBNs.contains(selectedBook.isbn) {
                        self.selectedISBNs.remove(selectedBook.isbn)
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                    } else {
                        self.selectedISBNs.insert(selectedBook.isbn)
                    }
                    self.updateCellSelection(at: indexPath, isSelected: self.selectedISBNs.contains(selectedBook.isbn))
                    self.updateEditButtonState()
                } else {
                    // 일반 모드에서는 책 상세로 이동
                    self.bookSelectionHandler?(selectedBook)
                }
            })
            .disposed(by: disposeBag)

        // State - Display Books (filtered or all)
        reactor.state
            .map { $0.displayBooks }
            .distinctUntilChanged { oldBooks, newBooks in
                // Compare by book ISBNs and count to detect changes
                guard let oldBooks = oldBooks, let newBooks = newBooks else {
                    return oldBooks == nil && newBooks == nil
                }
                guard oldBooks.count == newBooks.count else { return false }
                return oldBooks.map { $0.isbn } == newBooks.map { $0.isbn }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] books in
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
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] filters, isFavoriteEnabled in
                self?.updateNavigationTitle(with: filters, isFavoriteEnabled: isFavoriteEnabled)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.handleLoadingState(isLoading)
            })
            .disposed(by: disposeBag)
    }

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(LibraryCollectionViewCell.self, for: indexPath)
            cell.configure(with: item)
            
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

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // 편집 모드에서 선택된 셀인 경우 border 다시 적용
        guard isEditMode,
              let reactor = reactor,
              let books = reactor.currentState.displayBooks,
              indexPath.item < books.count else { return }

        let book = books[indexPath.item]
        let isSelected = selectedISBNs.contains(book.isbn)

        if isSelected {
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColor.forestGreen.cgColor
            cell.layer.cornerRadius = 8.0
        }
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
        let menuItems: [CircularMenuItem] = [
            // 1. 사진 찍기
            CircularMenuItem(name: "사진", image: UIImage(systemName: "camera")) { [weak self] in
                self?.capturePhoto(for: book)
            },
            // 2. 문장 저장
            CircularMenuItem(name: "문장", image: UIImage(systemName: "quote.bubble")) { [weak self] in
                self?.saveQuote(for: book)
            },
            // 3. 즐겨찾기
            CircularMenuItem(name: book.isFavorite ? "즐겨찾기 해제" : "즐겨찾기", image: UIImage(systemName: book.isFavorite ? "heart.fill" : "heart")) { [weak self] in
                self?.toggleFavorite(book)
            },
            // 4. 삭제
            CircularMenuItem(name: "삭제", image: UIImage(systemName: "trash")) { [weak self] in
                self?.deleteBook(book, at: indexPath)
            },
            // 5. 수정 (도서 정보 수정)
            CircularMenuItem(name: "수정", image: UIImage(systemName: "pencil")) { [weak self] in
                self?.editBookInfo(for: book)
            }
        ]

        return menuItems
    }

    // MARK: - Menu Actions

    // 1. 사진 찍기
    private func capturePhoto(for book: Book) {
        // Book 정보를 저장해두기 위해 임시로 저장
        self.tempBookForPhoto = book

        // CircularMenuViewController가 dismiss된 후에 카메라 present
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false

            self.present(imagePicker, animated: true)
        }
    }

    // 2. 문장 저장
    private func saveQuote(for book: Book) {
        // CircularMenuViewController가 dismiss된 후에 alert present
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showQuoteInputAlert(for: book)
        }
    }

    // 3. 즐겨찾기 토글
    private func toggleFavorite(_ book: Book) {
        guard let bookRepository = bookRepository else { return }

        bookRepository.toggleFavorite(bookId: book.id)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                print("✅ Favorite toggled: \(isFavorite)")
                // 데이터 새로고침
                self?.reactor?.action.onNext(.loadBooks)
            }, onError: { error in
                print("❌ Failed to toggle favorite: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    // 5. 도서 정보 수정
    private func editBookInfo(for book: Book) {
        // CircularMenuViewController가 dismiss된 후에 modal present
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showReadingInfoEdit(for: book)
        }
    }

    // 4. 삭제
    private func deleteBook(_ book: Book, at indexPath: IndexPath) {
        // CircularMenuViewController가 dismiss된 후에 alert present
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showDeleteConfirmation(for: book, at: indexPath)
        }
    }

    private func showDeleteConfirmation(for book: Book, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "도서 삭제",
            message: "'\(book.title)'을(를) 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            guard let self = self, let bookRepository = self.bookRepository else { return }

            bookRepository.deleteBooksByISBNs([book.isbn])
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    print("✅ Book deleted: \(book.cleanTitle)")
                    // 데이터 새로고침
                    self?.reactor?.action.onNext(.loadBooks)
                }, onError: { error in
                    print("❌ Failed to delete book: \(error.localizedDescription)")
                })
                .disposed(by: self.disposeBag)
        })

        present(alert, animated: true)
    }

    private func updateData(books: [Book]?) {
        guard let dataSource = dataSource, let books = books else { return }

        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        snapshot.appendItems(books, toSection: .book)
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
            tabBarController.navigationItem.title = "서재"
        } else {
            tabBarController.navigationItem.title = titleComponents.joined(separator: " ")
        }
    }

    // MARK: - Edit Mode Actions
    @objc public func filterButtonTapped() {
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

    @objc public func editButtonTapped() {
        if isEditMode {
            if selectedISBNs.isEmpty {
                // 편집 모드 종료
                exitEditMode()
            } else {
                // 선택된 책들 삭제
                deleteSelectedBooks()
            }
        } else {
            // 편집 모드 진입
            enterEditMode()
        }
    }

    private func enterEditMode() {
        isEditMode = true
        selectedISBNs.removeAll()

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        updateEditButtonState()
        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()
    }

    private func exitEditMode() {
        isEditMode = false
        selectedISBNs.removeAll()

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        updateEditButtonState()
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
            // 편집 모드: 필터 버튼을 취소 버튼으로 교체
            tabBarController.navigationItem.rightBarButtonItems = [editButton, cancelButton]
        } else {
            // 일반 모드: 취소 버튼을 필터 버튼으로 교체
            tabBarController.navigationItem.rightBarButtonItems = [editButton, filterButton]
        }
    }

    @objc private func cancelButtonTapped() {
        // 편집 모드 종료
        exitEditMode()
    }

    private func updateEditButtonState() {
        if isEditMode {
            if selectedISBNs.isEmpty {
                editButton.title = String(localized: .actionEdit)
                editButton.style = .plain
            } else {
                editButton.title = String(localized: .actionDelete)
                editButton.style = .plain
            }
        } else {
            editButton.title = String(localized: .actionEdit)
            editButton.style = .plain
        }
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
        let alert = UIAlertController(
            title: String(localized: .actionDelete),
            message: "선택한 \(selectedISBNs.count)개의 책을 삭제하시겠습니까?",
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
            title: "삭제 실패",
            message: "책 삭제에 실패했습니다. 다시 시도해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Quote Input
extension LibraryViewController {
    private func showQuoteInputAlert(for book: Book) {
        let alert = UIAlertController(
            title: "문장 저장",
            message: "저장할 문장을 입력하세요",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "문장 입력"
        }

        alert.addTextField { textField in
            textField.placeholder = "페이지 번호 (선택사항)"
            textField.keyboardType = .numberPad
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default) { [weak self, weak alert] _ in
            guard let quote = alert?.textFields?[0].text, !quote.isEmpty else { return }
            let pageNumberText = alert?.textFields?[1].text
            let pageNumber = pageNumberText.flatMap { Int($0) }

            self?.saveQuoteToRealm(quote: quote, pageNumber: pageNumber, for: book)
        })

        present(alert, animated: true)
    }

    private func saveQuoteToRealm(quote: String, pageNumber: Int?, for book: Book) {
        // TODO: QuoteRepository 주입 필요
        print("✅ Quote saved: \(quote), page: \(pageNumber ?? 0) for book: \(book.cleanTitle)")
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
        // TODO: PhotoRepository 주입 및 저장 로직
        print("✅ Photo saved for book: \(book.cleanTitle)")
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
                print("✅ Book reading info updated")
                self?.reactor?.action.onNext(.loadBooks)
            }, onError: { error in
                print("❌ Failed to update book reading info: \(error.localizedDescription)")
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

        // TODO: 레이블 글자 크기 계산 개선
        return (UIScreen.main.bounds.height / LibraryConstants.HeightCalculation.screenHeightDivider) + CGFloat(max(1, book.cleanTitle.count / LibraryConstants.HeightCalculation.titleCharacterDivider) * LibraryConstants.HeightCalculation.titleLineHeight) + CGFloat(max(1, book.author.count / LibraryConstants.HeightCalculation.authorCharacterDivider) * LibraryConstants.HeightCalculation.authorLineHeight)
    }
}
