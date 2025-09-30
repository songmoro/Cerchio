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

final class LibraryViewController: BaseViewController<LibraryReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, RealmBook>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RealmBook>

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!

    // Book selection handler
    var bookSelectionHandler: ((RealmBook) -> Void)?

    // Edit mode properties
    private var isEditMode = false
    private var selectedBookIds: Set<ObjectId> = []
    private var editButton: UIBarButtonItem!
    private var filterButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!

    // Repository
    private var bookRepository: BookRepositoryProtocol?

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
            title: NSLocalizedString("action.cancel", comment: "Cancel button"),
            style: .plain,
            target: self,
            action: #selector(cancelButtonTapped)
        )
    }

    func setBookRepository(_ repository: BookRepositoryProtocol) {
        bookRepository = repository
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

                let books = reactor.currentState.books
                guard let books, indexPath.item < books.count else { return }

                let selectedBook = books[indexPath.item]

                if self.isEditMode {
                    // 편집 모드에서는 선택/해제 토글
                    if self.selectedBookIds.contains(selectedBook.id) {
                        self.selectedBookIds.remove(selectedBook.id)
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                    } else {
                        self.selectedBookIds.insert(selectedBook.id)
                    }
                    self.updateCellSelection(at: indexPath, isSelected: self.selectedBookIds.contains(selectedBook.id))
                    self.updateEditButtonState()
                } else {
                    // 일반 모드에서는 책 상세로 이동
                    self.bookSelectionHandler?(selectedBook)
                }
            })
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.books }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] books in
                self?.updateData(books: books)
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


    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 뷰의 레이아웃이 완료된 후 컬렉션 뷰 레이아웃 업데이트
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    private func setupLongPressGesture(for cell: LibraryCollectionViewCell, with book: RealmBook, at indexPath: IndexPath) {
        // 기존 제스처 제거 (셀 재사용 시)
        cell.gestureRecognizers?.removeAll()

        // 편집 모드에서는 롱 프레스 제스처 비활성화
        guard !isEditMode else { return }

        // 셀이 화면에 완전히 표시된 후에 제스처 추가
        DispatchQueue.main.async { [weak self, weak cell] in
            guard let self = self, let cell = cell else { return }

            let menuItems = self.createMenuItems()

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
    
    private func createMenuItems() -> [CircularMenuItem] {
        let menuItems: [CircularMenuItem] = [
            CircularMenuItem(image: UIImage(systemName: "camera")) {
                print("카메라 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "photo")) {
                print("갤러리 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "video")) {
                print("비디오 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "doc")) {
                print("문서 선택됨")
            },
            CircularMenuItem(image: UIImage(systemName: "star")) {
                print("즐겨찾기 선택됨")
            }
        ]
        
        return menuItems
    }

    // MARK: - Menu Actions
    private func readBook(_ book: Book) {
        print("Reading book: \(book.title)")
//        bookSelectionHandler?(book)
    }

    private func toggleFavorite(_ book: Book) {
        print("Toggle favorite for book: \(book.title)")
        // TODO: 즐겨찾기 상태 변경 로직
        // reactor?.action.onNext(.toggleFavorite(book))
    }

    private func editBook(_ book: Book) {
        print("Edit book: \(book.title)")
        // TODO: 책 편집 화면으로 이동
        // coordinator?.showEditBook(book)
    }

    private func deleteBook(_ book: Book, at indexPath: IndexPath) {
        print("Delete book: \(book.title)")
        // TODO: 삭제 확인 알럿 표시 후 삭제 로직
        showDeleteConfirmation(for: book, at: indexPath)
    }

    private func showDeleteConfirmation(for book: Book, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "책 삭제",
            message: "'\(book.title)'을(를) 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            // TODO: 실제 삭제 로직
            // self?.reactor?.action.onNext(.deleteBook(book))
            print("Confirmed delete for book: \(book.title)")
        })

        present(alert, animated: true)
    }

    private func updateData(books: [RealmBook]?) {
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

    // MARK: - Edit Mode Actions
    @objc public func filterButtonTapped() {
        // TODO: 필터 기능 구현
        print("Filter button tapped")
    }

    @objc public func editButtonTapped() {
        if isEditMode {
            if selectedBookIds.isEmpty {
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
        selectedBookIds.removeAll()

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        updateEditButtonState()
        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()
    }

    private func exitEditMode() {
        isEditMode = false
        selectedBookIds.removeAll()

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        updateEditButtonState()
        updateNavigationBarForEditMode()
        updateCollectionViewForEditMode()

        // 모든 셀의 선택 상태 해제
        for indexPath in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: indexPath, animated: true)
            updateCellSelection(at: indexPath, isSelected: false)
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
            if selectedBookIds.isEmpty {
                editButton.title = NSLocalizedString("action.edit", comment: "Edit button")
                editButton.style = .plain
            } else {
                editButton.title = NSLocalizedString("action.delete", comment: "Delete button")
                editButton.style = .plain
            }
        } else {
            editButton.title = NSLocalizedString("action.edit", comment: "Edit button")
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
            cell.layer.borderColor = UIColor.systemBlue.cgColor
            cell.layer.cornerRadius = 8.0
        } else {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }

    private func deleteSelectedBooks() {
        let alert = UIAlertController(
            title: NSLocalizedString("action.delete", comment: "Delete action"),
            message: "선택한 \\(selectedBookIds.count)개의 책을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("action.cancel", comment: "Cancel action"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("action.delete", comment: "Delete action"), style: .destructive) { [weak self] _ in
            self?.performDeletion()
        })

        present(alert, animated: true)
    }

    private func performDeletion() {
        guard let reactor = reactor,
              let bookRepository = bookRepository else { return }

        // Get current books from reactor state
        guard let currentBooks = reactor.currentState.books else { return }

        // Find books to delete by IDs
        let booksToDelete = currentBooks.filter { selectedBookIds.contains($0.id) }

        guard !booksToDelete.isEmpty else { return }

        // 먼저 편집 모드를 종료하고 UI 업데이트 (무효화된 객체 참조 방지)
        exitEditMode()

        bookRepository.deleteBooksWithRelatedData(booksToDelete)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { _ in
                    // 데이터 새로고침
                    reactor.action.onNext(.loadBooks)
                },
                onError: { [weak self] error in
                    print("❌ Failed to delete books: \\(error.localizedDescription)")
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

extension LibraryViewController: MasonryLayoutProtocol {
    func collectionView(_ collectionView: UICollectionView, heightAtIndexPath indexPath: IndexPath) -> CGFloat {
        guard let reactor = reactor else { return LibraryConstants.HeightCalculation.defaultHeight }

        let books = reactor.currentState.books
        guard let books = books, indexPath.item < books.count else { return LibraryConstants.HeightCalculation.defaultHeight }

        let book = books[indexPath.item]

        // TODO: 레이블 글자 크기 계산 개선
        return (UIScreen.main.bounds.height / LibraryConstants.HeightCalculation.screenHeightDivider) + CGFloat(max(1, book.cleanTitle.count / LibraryConstants.HeightCalculation.titleCharacterDivider) * LibraryConstants.HeightCalculation.titleLineHeight) + CGFloat(max(1, book.author.count / LibraryConstants.HeightCalculation.authorCharacterDivider) * LibraryConstants.HeightCalculation.authorLineHeight)
    }
}
