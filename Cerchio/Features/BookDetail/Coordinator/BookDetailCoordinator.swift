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
        // 뒤로가기 버튼 (기본 제공)
        viewController.navigationItem.title = book.cleanTitle

        // 즐겨찾기 버튼
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: book.isFavorite ? "heart.fill" : "heart"),
            style: .plain,
            target: self,
            action: #selector(favoriteButtonTapped)
        )

        // 삭제 버튼
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )

        viewController.navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]

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

    // MARK: - Action Methods
    @objc private func favoriteButtonTapped() {
        currentReactor?.action.onNext(.toggleFavorite)
    }

    @objc private func deleteButtonTapped() {
        // TODO: 삭제 확인 알림 및 삭제 기능 구현
        print("Delete button tapped for book: \(book.cleanTitle)")
        showDeleteConfirmation()
    }

    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "도서 삭제",
            message: "'\(book.cleanTitle)'을(를) 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        let deleteAction = UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.deleteBook()
        }

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        alert.addAction(deleteAction)
        alert.addAction(cancelAction)

        navigationController.present(alert, animated: true)
    }

    private func deleteBook() {
        let bookRepository = dependencies.serviceFactory.createBookRepository()

        bookRepository.deleteBooksByISBNs([book.isbn])
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    guard let self = self else { return }
                    print("✅ Book deleted: \(self.book.cleanTitle)")
                    self.navigationController.popViewController(animated: true)
                },
                onError: { [weak self] error in
                    print("❌ Failed to delete book: \(error.localizedDescription)")
                    self?.showDeleteErrorAlert()
                }
            )
            .disposed(by: disposeBag)
    }

    private func showDeleteErrorAlert() {
        let alert = UIAlertController(
            title: "삭제 실패",
            message: "도서를 삭제하는 중 오류가 발생했습니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default))
        navigationController.present(alert, animated: true)
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
