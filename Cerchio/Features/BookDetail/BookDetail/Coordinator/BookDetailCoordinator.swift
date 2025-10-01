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

    // MARK: - Private Methods
    private func showBookDetailViewController() {
        let bookDetailViewController = BookDetailViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let bookDetailReactor = BookDetailReactor(book: book, bookRepository: bookRepository)

        // Reactor 참조 저장
        self.currentReactor = bookDetailReactor

        bookDetailViewController.coordinator = self
        bookDetailViewController.reactor = bookDetailReactor

        // ServiceFactory 주입
        bookDetailViewController.setServiceFactory(dependencies.serviceFactory)

        // 탭바 숨김 설정
        bookDetailViewController.hidesBottomBarWhenPushed = true

        // 네비게이션 아이템 설정
        setupNavigationItems(for: bookDetailViewController, reactor: bookDetailReactor)

        navigationController.pushViewController(bookDetailViewController, animated: true)
    }

    private func setupNavigationItems(for viewController: UIViewController, reactor: BookDetailReactor) {
        guard let bookDetailVC = viewController as? BookDetailViewController else { return }

        // 뒤로가기 버튼 (기본 제공)
        viewController.navigationItem.title = book.cleanTitle

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
    func showEditBook() {
        // TODO: EditBookCoordinator 구현 시 추가
        print("Show edit book: \(book.cleanTitle)")
    }

    func showQuoteEntry() {
        // TODO: QuoteEntryCoordinator 구현 시 추가
        print("Show quote entry for book: \(book.cleanTitle)")
    }

    func showReadingProgress() {
        // TODO: ReadingProgressCoordinator 구현 시 추가
        print("Show reading progress for book: \(book.cleanTitle)")
    }
}
