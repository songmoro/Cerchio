//
//  BookDetailCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

enum BookDetailNavigationEvent: NavigationEventProtocol {
    case showEditBook(Book)
    case showQuoteEntry(Book)
    case showReadingProgress(Book)
    case deleteBook(Book)
}

// MARK: - BookDetail Dependencies
struct BookDetailDependencies {
    let serviceFactory: ServiceFactory
    let book: Book
}

final class BookDetailCoordinator: BaseCoordinator, Coordinatable {
    typealias Dependencies = BookDetailDependencies

    // MARK: - Properties
    private var dependencies: BookDetailDependencies!
    private weak var currentReactor: BookDetailReactor?
    private var photoCompletionHandler: ((UIImage) -> Void)?

    private var book: Book {
        return dependencies.book
    }

    // MARK: - Initialization
    override init(navigationController: UINavigationController) {
        super.init(navigationController: navigationController)
    }

    // MARK: - BaseCoordinator
    override func start() {
        fatalError("Use start(with dependencies:) instead")
    }

    func start(with dependencies: BookDetailDependencies) {
        self.dependencies = dependencies
        showBookDetailViewController()
        bindNavigationEvents()
    }

    // MARK: - Setup (for session restoration)
    func setupDependencies(serviceFactory: ServiceFactory, book: Book) {
        self.dependencies = BookDetailDependencies(serviceFactory: serviceFactory, book: book)
    }

    // MARK: - Private Methods
    private func showBookDetailViewController() {
        let bookDetailViewController = BookDetailViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let service = BookDetailService(serviceFactory: dependencies.serviceFactory)
        let bookDetailReactor = BookDetailReactor(book: book, bookRepository: bookRepository, service: service)

        // Reactor 참조 저장
        self.currentReactor = bookDetailReactor

        bookDetailViewController.coordinator = self
        bookDetailViewController.reactor = bookDetailReactor

        // 뒤로가기 버튼 텍스트 제거
        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        bookDetailViewController.navigationItem.backBarButtonItem = backBarButtonItem

        // 네비게이션 아이템 설정
        setupNavigationItems(for: bookDetailViewController, reactor: bookDetailReactor)

        navigationController.pushViewController(bookDetailViewController, animated: true)
    }

    private func setupNavigationItems(for viewController: UIViewController, reactor: BookDetailReactor) {
        guard let bookDetailVC = viewController as? BookDetailViewController else { return }

        // Navigation bar appearance - transparent to show background
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()

        viewController.navigationItem.standardAppearance = appearance
        viewController.navigationItem.scrollEdgeAppearance = appearance
        viewController.navigationItem.compactAppearance = appearance

        // 타이틀 제거 (도서 정보 헤더에 이미 표시됨)
        viewController.navigationItem.title = nil

        // 즐겨찾기 버튼
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: book.isFavorite ? "heart.fill" : "heart"),
            style: .plain,
            target: nil,
            action: nil
        )

        // 삭제 버튼
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: nil,
            action: nil
        )

        viewController.navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]

        // ViewController에 버튼 설정 (Rx 바인딩은 ViewController에서 처리)
        bookDetailVC.setFavoriteButton(favoriteButton)
        bookDetailVC.setDeleteButton(deleteButton)

        // 타이틀이 제거되었으므로 타이틀 업데이트 구독 제거
        // reactor.state
        //     .map { $0.book.cleanTitle }
        //     .distinctUntilChanged()
        //     .observe(on: MainScheduler.instance)
        //     .subscribe(onNext: { [weak viewController] title in
        //         viewController?.navigationItem.title = title
        //     })
        //     .disposed(by: disposeBag)

        // 즐겨찾기 상태 변경 감지
        reactor.state
            .map { $0.isFavorite }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak favoriteButton] isFavorite in
                let imageName = isFavorite ? "heart.fill" : "heart"
                favoriteButton?.image = UIImage(systemName: imageName)
            })
            .disposed(by: disposeBag)

        // 삭제 완료 감지 (Coordinator가 직접 구독)
        reactor.state
            .map { $0.isDeleted }
            .distinctUntilChanged()
            .filter { $0 == true }
            .take(1) // 한 번만 실행
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                // 삭제 완료 후 화면 닫기
                self?.navigationController.popViewController(animated: true)
                self?.finish()
            })
            .disposed(by: disposeBag)
    }

    private func bindNavigationEvents() {
        navigationEvents
            .subscribe(onNext: { [weak self] event in
                self?.handleNavigationEvent(event)
            })
            .disposed(by: disposeBag)
    }

    private func handleNavigationEvent(_ event: NavigationEvent) {
        switch event {
        case .back:
            navigationController.popViewController(animated: true)
        case .close:
            navigationController.dismiss(animated: true)
        case .finished:
            // 삭제는 setupNavigationItems에서 직접 처리
            break
        }
    }

    // MARK: - Navigation Methods
    func showEditBook() {
        // TODO: EditBookCoordinator 구현 시 추가
        print("Show edit book: \(book.cleanTitle)")
    }

    func showQuoteEntry() {
        let bookId = String(describing: dependencies.book.id)

        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController,
            dependencies: QuoteSaveCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: dependencies.serviceFactory
            )
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quoteSaved(let quote):
                    print(" Quote saved: \(quote)")
                    self?.currentReactor?.action.onNext(.loadQuotes)
                case .cancelled:
                    print("📝 Quote save cancelled")
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    func showReadingProgress() {
        // TODO: ReadingProgressCoordinator 구현 시 추가
        print("Show reading progress for book: \(book.cleanTitle)")
    }

    func showQuoteShare(quoteData: QuoteShareData) {
        let quoteShareCoordinator = QuoteShareCoordinator(
            navigationController: navigationController,
            dependencies: QuoteShareCoordinator.Dependencies(quoteData: quoteData)
        )

        addChildCoordinator(quoteShareCoordinator)

        quoteShareCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .imageExported(let image):
                    print(" Quote image exported")
                    self?.saveImageToPhotoLibrary(image)
                case .cancelled:
                    print("📝 Quote share cancelled")
                }
                self?.removeChildCoordinator(quoteShareCoordinator)
            })
            .disposed(by: disposeBag)

        quoteShareCoordinator.start()
    }

    func showPhotoCapture(completion: @escaping (UIImage) -> Void) {
        guard let topViewController = navigationController.topViewController else { return }

        CameraPermissionManager.shared.handleCameraPermission(from: topViewController) { [weak self] granted in
            guard granted else {
                print(" Camera permission denied")
                return
            }

            let cameraVC = CameraViewController()
            cameraVC.delegate = self
            cameraVC.modalPresentationStyle = .fullScreen

            // Store completion for later use
            self?.photoCompletionHandler = completion

            self?.navigationController.present(cameraVC, animated: true)
        }
    }

    func showAllQuotes() {
        let bookId = String(describing: dependencies.book.id)

        let quoteListCoordinator = QuoteListCoordinator(
            navigationController: navigationController,
            dependencies: QuoteListCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: dependencies.serviceFactory
            )
        )

        addChildCoordinator(quoteListCoordinator)

        quoteListCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quotesUpdated:
                    print(" Quotes updated, refreshing...")
                    self?.currentReactor?.action.onNext(.loadQuotes)
                case .dismissed:
                    print("📝 Quote list dismissed")
                }
                self?.removeChildCoordinator(quoteListCoordinator)
            })
            .disposed(by: disposeBag)

        quoteListCoordinator.start()
    }

    func showAllPhotos() {
        let bookId = String(describing: dependencies.book.id)

        let photoListCoordinator = PhotoListCoordinator(
            navigationController: navigationController,
            dependencies: PhotoListCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: dependencies.serviceFactory,
                onAddPhotoTapped: { [weak self] in
                    self?.showPhotoCapture { image in
                        self?.currentReactor?.action.onNext(.savePhoto(image))
                    }
                }
            )
        )

        addChildCoordinator(photoListCoordinator)

        photoListCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .photosUpdated:
                    print(" Photos updated, refreshing...")
                    self?.currentReactor?.action.onNext(.loadPhotos)
                case .dismissed:
                    print("📷 Photo list dismissed")
                }
                self?.removeChildCoordinator(photoListCoordinator)
            })
            .disposed(by: disposeBag)

        photoListCoordinator.start()
    }

    func showReadingSessionList() {
        let viewController = ReadingSessionListViewController()
        let service = BookDetailService(serviceFactory: dependencies.serviceFactory)
        let reactor = ReadingSessionListReactor(
            bookId: book.id,
            bookTitle: book.cleanTitle,
            service: service
        )
        viewController.reactor = reactor

        // 독서 기록 추가 콜백 설정
        viewController.onAddRecordRequested = { [weak self, weak viewController] in
            self?.showReadingRecordEntry(reloadHandler: {
                viewController?.reloadSessions()
            })
        }

        navigationController.pushViewController(viewController, animated: true)
    }

    func showReadingRecordEntry(reloadHandler: (() -> Void)? = nil) {
        let readingRecordCoordinator = ReadingRecordCoordinator(
            navigationController: navigationController,
            dependencies: ReadingRecordCoordinator.Dependencies(
                bookId: book.id,
                serviceFactory: dependencies.serviceFactory
            )
        )

        addChildCoordinator(readingRecordCoordinator)

        readingRecordCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .recordSaved(let content):
                    print(" Reading record saved: \(content)")
                    // Trigger statistics reload
                    self?.currentReactor?.action.onNext(.loadReadingStatistics)
                    reloadHandler?()
                case .cancelled:
                    print("📝 Reading record cancelled")
                }
                self?.removeChildCoordinator(readingRecordCoordinator)
            })
            .disposed(by: disposeBag)

        readingRecordCoordinator.start()
    }

    func showEditBookInfo() {
        let editBookInfoCoordinator = EditBookInfoCoordinator(
            navigationController: navigationController,
            dependencies: EditBookInfoCoordinator.Dependencies(
                book: book,
                serviceFactory: dependencies.serviceFactory
            )
        )

        addChildCoordinator(editBookInfoCoordinator)

        editBookInfoCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .bookInfoUpdated(let updatedBook):
                    print(" Book info updated - customTitle: \(updatedBook.customTitle ?? "nil"), refreshing...")
                    // 업데이트된 Book으로 BookDetail 다시 로드
                    self?.currentReactor?.action.onNext(.updateBookAndReload(updatedBook))
                case .cancelled:
                    print("📝 Book info edit cancelled")
                }
                self?.removeChildCoordinator(editBookInfoCoordinator)
            })
            .disposed(by: disposeBag)

        editBookInfoCoordinator.start()
    }

    func showResetAndDelete() {
        let viewController = ResetAndDeleteViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let reactor = ResetAndDeleteReactor(
            book: book,
            bookRepository: bookRepository,
            serviceFactory: dependencies.serviceFactory
        )
        viewController.reactor = reactor

        navigationController.pushViewController(viewController, animated: true)
    }

    func showQuoteEdit(quote: String, pageNumber: Int?, date: Date) {
        let bookId = String(describing: dependencies.book.id)

        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController,
            dependencies: QuoteSaveCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: dependencies.serviceFactory,
                existingQuote: quote,
                existingPageNumber: pageNumber
            )
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quoteSaved(let updatedQuote):
                    print(" Quote updated: \(updatedQuote)")
                    self?.currentReactor?.action.onNext(.loadQuotes)
                case .cancelled:
                    print("📝 Quote edit cancelled")
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    // MARK: - Helper Methods
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        guard let topViewController = navigationController.topViewController else { return }

        PhotoLibraryPermissionManager.shared.handlePhotoLibraryPermission(from: topViewController) { [weak self] granted in
            guard granted else {
                print(" Photo library permission denied")
                return
            }

            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.imageSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc private func imageSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        guard let topViewController = navigationController.topViewController else { return }

        let alert = UIAlertController(
            title: error == nil ? String(localized: .photoSaveSuccessTitle) : String(localized: .photoSaveFailureTitle),
            message: error == nil ? String(localized: .photoSaveSuccessMessage) : String(localized: .photoSaveFailureMessage),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .actionConfirm), style: .default))
        topViewController.present(alert, animated: true)
    }
}

// MARK: - CameraViewControllerDelegate
extension BookDetailCoordinator: CameraViewControllerDelegate {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            self?.photoCompletionHandler?(image)
            self?.photoCompletionHandler = nil
        }
    }

    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.photoCompletionHandler = nil
        }
    }
}
