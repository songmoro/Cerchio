//
//  LibraryCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

enum LibraryNavigationEvent: NavigationEventProtocol {
    case showBookDetail(Book)
    case showAddBook
    case showSearch
    case showSettings
}

struct LibraryDependencies {
    let serviceFactory: ServiceFactory
}

final class LibraryCoordinator: BaseCoordinator, Coordinatable {
    typealias Dependencies = LibraryDependencies

    private var dependencies: LibraryDependencies!
    private var photoCompletionHandler: ((UIImage, Book) -> Void)?
    private var currentBook: Book?

    override func start() {
        fatalError("Use start(with dependencies:) instead")
    }

    func start(with dependencies: LibraryDependencies) {
        self.dependencies = dependencies
        showLibraryViewController()
        bindNavigationEvents()
    }

    private func showLibraryViewController() {
        let libraryViewController = LibraryViewController()

        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let tagRepository = dependencies.serviceFactory.createTagRepository()
        let quoteRepository = dependencies.serviceFactory.createQuoteRepository()
        let photoRepository = dependencies.serviceFactory.createPhotoRepository()
        let libraryReactor = LibraryReactor(bookRepository: bookRepository, tagRepository: tagRepository)

        libraryViewController.coordinator = self
        libraryViewController.reactor = libraryReactor
        libraryViewController.setBookRepository(bookRepository)
        libraryViewController.setTagRepository(tagRepository)
        libraryViewController.setQuoteRepository(quoteRepository)
        libraryViewController.setPhotoRepository(photoRepository)

        libraryViewController.bookSelectionHandler = { [weak self] book in
            self?.showBookDetail(book)
        }

        navigationController.setViewControllers([libraryViewController], animated: false)
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
            finish()
        }
    }

    func showBookDetail(_ book: Book) {
        let bookDetailDependencies = BookDetailDependencies(
            serviceFactory: dependencies.serviceFactory,
            book: book
        )
        let bookDetailCoordinator = BookDetailCoordinator(navigationController: navigationController)
        addChildCoordinator(bookDetailCoordinator)
        bookDetailCoordinator.start(with: bookDetailDependencies)
    }

    func showAddBook() {
    }

    func showSearch() {
    }

    func showSettings() {
    }

    func showPhotoCapture(for book: Book, completion: @escaping (UIImage, Book) -> Void) {
        guard let topViewController = navigationController.topViewController else { return }

        CameraPermissionManager.shared.handleCameraPermission(from: topViewController) { [weak self] granted in
            guard granted else {
                return
            }

            let cameraVC = CameraViewController()
            cameraVC.delegate = self
            cameraVC.modalPresentationStyle = .fullScreen

            self?.photoCompletionHandler = completion
            self?.currentBook = book

            self?.navigationController.present(cameraVC, animated: true)
        }
    }
}

extension LibraryCoordinator: CameraViewControllerDelegate {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self, let book = self.currentBook else { return }
            self.photoCompletionHandler?(image, book)
            self.photoCompletionHandler = nil
            self.currentBook = nil
        }
    }

    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.photoCompletionHandler = nil
            self?.currentBook = nil
        }
    }
}
