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

final class LibraryCoordinator: BaseCoordinator {

    override func start() {
        showLibraryViewController()
        bindNavigationEvents()
    }

    private func showLibraryViewController() {
        let libraryViewController = LibraryViewController()
        let libraryReactor = LibraryReactor()

        libraryViewController.coordinator = self
        libraryViewController.reactor = libraryReactor

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

    // MARK: - Navigation Methods

    func showBookDetail(_ book: Book) {
        let bookDetailCoordinator = BookDetailCoordinator(
            navigationController: navigationController,
            book: book
        )
        addChildCoordinator(bookDetailCoordinator)
        bookDetailCoordinator.start()
    }

    func showAddBook() {
        // TODO: AddBookCoordinator 구현 시 추가
        print("Show add book")
    }

    func showSearch() {
        // TODO: SearchCoordinator 구현 시 추가
        print("Show search")
    }

    func showSettings() {
        // TODO: SettingsCoordinator 구현 시 추가
        print("Show settings")
    }
}
