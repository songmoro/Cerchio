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

struct BookDetailDependencies {
    let serviceFactory: ServiceFactory
    let book: Book
}

final class BookDetailCoordinator: BaseCoordinator, Coordinatable {
    typealias Dependencies = BookDetailDependencies

    private var dependencies: BookDetailDependencies!
    private weak var currentReactor: BookDetailReactor?
    private var photoCompletionHandler: ((UIImage) -> Void)?

    private var book: Book {
        return dependencies.book
    }

    override init(navigationController: UINavigationController) {
        super.init(navigationController: navigationController)
    }

    override func start() {
        fatalError("Use start(with dependencies:) instead")
    }

    func start(with dependencies: BookDetailDependencies) {
        self.dependencies = dependencies
        showBookDetailViewController()
        bindNavigationEvents()
    }

    func setupDependencies(serviceFactory: ServiceFactory, book: Book) {
        self.dependencies = BookDetailDependencies(serviceFactory: serviceFactory, book: book)
    }

    private func showBookDetailViewController() {
        let bookDetailViewController = BookDetailViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let service = BookDetailService(serviceFactory: dependencies.serviceFactory)
        let bookDetailReactor = BookDetailReactor(book: book, bookRepository: bookRepository, service: service)

        self.currentReactor = bookDetailReactor

        bookDetailViewController.coordinator = self
        bookDetailViewController.reactor = bookDetailReactor

        let backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        bookDetailViewController.navigationItem.backBarButtonItem = backBarButtonItem

        setupNavigationItems(for: bookDetailViewController, reactor: bookDetailReactor)

        navigationController.pushViewController(bookDetailViewController, animated: true)
    }

    private func setupNavigationItems(for viewController: UIViewController, reactor: BookDetailReactor) {
        guard let bookDetailVC = viewController as? BookDetailViewController else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()

        viewController.navigationItem.standardAppearance = appearance
        viewController.navigationItem.scrollEdgeAppearance = appearance
        viewController.navigationItem.compactAppearance = appearance

        viewController.navigationItem.title = nil

        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: book.isFavorite ? "heart.fill" : "heart"),
            style: .plain,
            target: nil,
            action: nil
        )

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: nil,
            action: nil
        )

        viewController.navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]

        bookDetailVC.setFavoriteButton(favoriteButton)
        bookDetailVC.setDeleteButton(deleteButton)

        reactor.state
            .map { $0.isFavorite }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak favoriteButton] isFavorite in
                let imageName = isFavorite ? "heart.fill" : "heart"
                favoriteButton?.image = UIImage(systemName: imageName)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isDeleted }
            .distinctUntilChanged()
            .filter { $0 == true }
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
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
            break
        }
    }

    func showEditBook() {
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
                case .quoteSaved:
                    self?.currentReactor?.action.onNext(.loadQuotes)
                case .cancelled:
                    break
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    func showReadingProgress() {
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
                    self?.saveImageToPhotoLibrary(image)
                case .cancelled:
                    break
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
                return
            }

            let cameraVC = CameraViewController()
            cameraVC.delegate = self
            cameraVC.modalPresentationStyle = .fullScreen

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
                    self?.currentReactor?.action.onNext(.loadQuotes)
                case .dismissed:
                    break
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
                    self?.currentReactor?.action.onNext(.loadPhotos)
                case .dismissed:
                    break
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
                case .recordSaved:
                    self?.currentReactor?.action.onNext(.loadReadingStatistics)
                    reloadHandler?()
                case .cancelled:
                    break
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
                    self?.currentReactor?.action.onNext(.updateBookAndReload(updatedBook))
                case .cancelled:
                    break
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
                case .quoteSaved:
                    self?.currentReactor?.action.onNext(.loadQuotes)
                case .cancelled:
                    break
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    private func saveImageToPhotoLibrary(_ image: UIImage) {
        guard let topViewController = navigationController.topViewController else { return }

        PhotoLibraryPermissionManager.shared.handlePhotoLibraryPermission(from: topViewController) { [weak self] granted in
            guard granted else {
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
