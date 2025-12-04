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

    var bookSelectionHandler: ((Book) -> Void)?

    private var isEditMode = false
    private var selectedISBNs: Set<String> = []
    private var editButton: UIBarButtonItem!
    private var filterButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    private var selectAllButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!

    private var bookRepository: BookRepositoryProtocol?
    private var tagRepository: TagRepositoryProtocol?
    private var quoteRepository: QuoteRepositoryProtocol?
    private var photoRepository: PhotoRepositoryProtocol?

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

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = nil
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        if isEditMode {
            exitEditMode()
        }

        reactor?.action.onNext(.loadBooks)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        DominantColorCache.shared.clearScope("library")
    }

    func setEditButton(_ button: UIBarButtonItem) {
        editButton = button

        editButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.editButtonTapped()
            })
            .disposed(by: disposeBag)
    }

    func setFilterButton(_ button: UIBarButtonItem) {
        filterButton = button

        filterButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.filterButtonTapped()
            })
            .disposed(by: disposeBag)

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
        Observable.just(LibraryReactor.Action.loadBooks)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        refreshControl.rx.controlEvent(.valueChanged)
            .map { LibraryReactor.Action.loadBooks }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == false }
            .subscribe(onNext: { [weak self] selectedBook in
                self?.bookSelectionHandler?(selectedBook)
            })
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] selectedBook in
                guard let self = self else { return }

                if self.selectedISBNs.contains(selectedBook.isbn) {
                    if let indexPath = self.dataSource.indexPath(for: selectedBook) {
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                    }
                } else {
                    self.selectedISBNs.insert(selectedBook.isbn)
                    if let indexPath = self.dataSource.indexPath(for: selectedBook) {
                        self.updateCellSelection(at: indexPath, isSelected: true)
                    }
                    self.updateNavigationBarForEditMode()
                }
            })
            .disposed(by: disposeBag)

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

        reactor.state
            .map { $0.displayBooks }
            .distinctUntilChanged { oldBooks, newBooks in
                guard let oldBooks = oldBooks, let newBooks = newBooks else {
                    return oldBooks == nil && newBooks == nil
                }
                guard oldBooks.count == newBooks.count else { return false }

                let oldISBNs = oldBooks.map { $0.isbn }
                let newISBNs = newBooks.map { $0.isbn }
                guard oldISBNs == newISBNs else { return false }

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

            let isLeftColumn = indexPath.item % 2 == 0
            cell.configure(with: item, isLeftColumn: isLeftColumn)

            self?.setupLongPressGesture(for: cell, with: item, at: indexPath)
            return cell
        }

        collectionView.dataSource = dataSource

        setupInitialSnapshot()
    }

    private func setupInitialSnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupLongPressGesture(for cell: LibraryCollectionViewCell, with book: Book, at indexPath: IndexPath) {
        guard !isEditMode else {
            removeLongPressGesture(from: cell)
            return
        }

        removeLongPressGesture(from: cell)

        DispatchQueue.main.async { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }

            let menuItems = self.createMenuItems(for: book, at: indexPath)

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
        if let gestureRecognizers = cell.gestureRecognizers {
            for gesture in gestureRecognizers {
                if gesture is UILongPressGestureRecognizer {
                    cell.removeGestureRecognizer(gesture)
                }
            }
        }
    }
    
    private func createMenuItems(for book: Book, at indexPath: IndexPath) -> [CircularMenuItem] {
        let isFavorite = getCurrentFavoriteState(for: book)

        let menuItems: [CircularMenuItem] = [
            CircularMenuItem(name: String(localized: .circularMenuLibraryTakePhoto), image: UIImage(systemName: "camera")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.capturePhoto(for: book)
            },
            CircularMenuItem(name: String(localized: .circularMenuBookDetailSaveQuote), image: UIImage(systemName: "quote.bubble")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.saveQuote(for: book)
            },
            CircularMenuItem(name: isFavorite ? String(localized: .circularMenuBookDetailRemoveFavorite) : String(localized: .circularMenuBookDetailAddFavorite), image: UIImage(systemName: isFavorite ? "heart.fill" : "heart")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.toggleFavorite(book)
            },
            CircularMenuItem(name: String(localized: .circularMenuCommonDelete), image: UIImage(systemName: "trash")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.deleteBook(book, at: indexPath)
            },
            CircularMenuItem(name: String(localized: .circularMenuCommonEdit), image: UIImage(systemName: "pencil")) { [weak self] in
                HapticFeedbackManager.shared.selection()
                self?.editBookInfo(for: book)
            }
        ]

        return menuItems
    }

    private func getCurrentFavoriteState(for book: Book) -> Bool {
        guard let reactor = reactor,
              let books = reactor.currentState.displayBooks,
              let currentBook = books.first(where: { $0.isbn == book.isbn }) else {
            return book.isFavorite
        }
        return currentBook.isFavorite
    }

    private func capturePhoto(for book: Book) {
        guard let coordinator = coordinator as? LibraryCoordinator else { return }

        coordinator.showPhotoCapture(for: book) { [weak self] image, book in
            self?.savePhotoToRealm(image: image, for: book)
        }
    }

    private func saveQuote(for book: Book) {
        showQuoteInputAlert(for: book)
    }

    private func toggleFavorite(_ book: Book) {
        guard let bookRepository = bookRepository else { return }

        let bookId = book.id

        bookRepository.toggleFavorite(bookId: bookId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                self?.reactor?.action.onNext(.loadBooks)
            }, onError: { error in
                print(" Failed to toggle favorite: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }

    private func editBookInfo(for book: Book) {
        showReadingInfoEdit(for: book)
    }

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

        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        snapshot.appendItems(books, toSection: .book)

        dataSource.apply(snapshot, animatingDifferences: true)

        preloadColorsForBooks(books)
    }

    private func preloadColorsForBooks(_ books: [Book]) {
        let imageKeys = books.map { $0.customCoverImagePath ?? $0.image }

        Task {
            await DominantColorCache.shared.loadAndCacheColors(
                imageKeys: imageKeys,
                scope: "library"
            )
        }
    }

    private func handleLoadingState(_ isLoading: Bool) {
        if isLoading {
        } else {
        }
    }

    private func updateNavigationTitle(with filters: [String], isFavoriteEnabled: Bool) {
        guard let tabBarController = tabBarController else { return }

        var titleComponents: [String] = []

        if isFavoriteEnabled {
            titleComponents.append("♥")
        }

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

    private func filterButtonTapped() {
        guard let tagRepository = tagRepository else { return }

        tagRepository.getAllTags()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] allTags in
                guard let self = self else { return }

                let uniqueTags = Array(Set(allTags.map { $0.tagName })).sorted()

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
                reactor.action.onNext(.clearFilters)
            } else {
                reactor.action.onNext(.applyTagFilters(selectedTags, favoriteOnly: favoriteOnly))
            }
        }

        let navController = UINavigationController(rootViewController: filterVC)
        present(navController, animated: true)
    }

    private func editButtonTapped() {
        enterEditMode()
    }

    private func enterEditMode() {
        if let reactor = reactor,
           (!reactor.currentState.activeFilters.isEmpty || reactor.currentState.isFavoriteFilterEnabled) {
            reactor.action.onNext(.clearFilters)
        }

        isEditMode = true
        selectedISBNs.removeAll()

        HapticFeedbackManager.shared.impact()

        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()
    }

    private func exitEditMode() {
        isEditMode = false
        selectedISBNs.removeAll()

        HapticFeedbackManager.shared.impact()

        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()

        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: true)
            updateCellSelection(at: indexPath, isSelected: false)
        }

        for cell in collectionView.visibleCells {
            cell.layer.borderWidth = 0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }

    private func updateNavigationBarForEditMode() {
        guard let tabBarController = tabBarController else { return }

        if isEditMode {
            if selectedISBNs.isEmpty {
                tabBarController.navigationItem.leftBarButtonItem = cancelButton
                tabBarController.navigationItem.rightBarButtonItems = [selectAllButton]
            } else {
                tabBarController.navigationItem.leftBarButtonItem = cancelButton
                tabBarController.navigationItem.rightBarButtonItems = [deleteButton]
            }
        } else {
            tabBarController.navigationItem.leftBarButtonItem = nil
            tabBarController.navigationItem.rightBarButtonItems = [editButton, filterButton]
        }
    }

    private func cancelButtonTapped() {
        exitEditMode()
    }

    private func selectAllButtonTapped() {
        guard let reactor = reactor,
              let books = reactor.currentState.displayBooks else { return }

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

        let isbnsToDelete = Array(selectedISBNs)
        let currentFilters = reactor.currentState.activeFilters
        let isFavoriteEnabled = reactor.currentState.isFavoriteFilterEnabled

        guard !isbnsToDelete.isEmpty else { return }

        exitEditMode()

        bookRepository.deleteBooksByISBNs(isbnsToDelete)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let self = self, let reactor = self.reactor else { return }

                    reactor.action.onNext(.loadBooks)

                    if !currentFilters.isEmpty || isFavoriteEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            reactor.action.onNext(.applyTagFilters(currentFilters, favoriteOnly: isFavoriteEnabled))
                        }
                    }
                },
                onError: { [weak self] error in
                    print("Failed to delete books: \(error.localizedDescription)")
                    self?.showDeleteErrorAlert()
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
                },
                onError: { error in
                    print(" Failed to save quote: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)
    }

    private func savePhotoToRealm(image: UIImage, for book: Book) {
        guard let photoRepository = photoRepository else {
            return
        }

        let bookId = String(describing: book.id)

        let imageName = ImageStorageManager.shared.generateUniqueImageName(for: bookId)
        guard let localPath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
            return
        }

        let realmPhoto = RealmPhoto(
            bookId: bookId,
            localImagePath: localPath
        )

        photoRepository.savePhoto(realmPhoto)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] savedPhoto in
                    guard self != nil else { return }
                },
                onError: { [weak self] error in
                    guard self != nil else { return }
                    print(" Failed to save photo: \(error.localizedDescription)")
                    _ = ImageStorageManager.shared.deleteImage(atPath: localPath)
                }
            )
            .disposed(by: disposeBag)
    }
}

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

        let numberOfColumns: CGFloat = CGFloat(MasonryConstants.Layout.numberOfColumns)
        let contentWidth = collectionView.bounds.width
        let columnWidth = contentWidth / numberOfColumns

        let isLeftColumn = indexPath.item % 2 == 0
        let masonryLeftPadding: CGFloat = isLeftColumn ? 8 : 2
        let masonryRightPadding: CGFloat = isLeftColumn ? 2 : 8

        let cellInset = LibraryConstants.Layout.cellInset

        let availableWidth = columnWidth - masonryLeftPadding - masonryRightPadding - (cellInset * 2)

        let backgroundHeight = availableWidth

        let titleHeight = calculateLabelHeight(
            text: book.cleanTitle,
            font: .custom(weight: .semiBold, size: LibraryConstants.Typography.titleFontSize),
            width: availableWidth
        )

        let authorHeight = calculateLabelHeight(
            text: book.author,
            font: .custom(weight: .regular, size: LibraryConstants.Typography.authorFontSize),
            width: availableWidth
        ) * 2

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
        label.numberOfLines = 0

        let size = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return ceil(size.height)
    }
}
