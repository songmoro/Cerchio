//
//  EditBookInfoCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 10/13/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

final class EditBookInfoCoordinator: BaseCoordinator {
    enum Result {
        case bookInfoUpdated(Book)
        case cancelled
    }

    struct Dependencies {
        let book: Book
        let serviceFactory: ServiceFactory
    }

    // MARK: - Properties
    private let dependencies: Dependencies
    private let resultRelay = PublishRelay<Result>()

    var result: Observable<Result> {
        resultRelay.asObservable()
    }

    // MARK: - Initialization
    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(navigationController: navigationController)
    }

    // MARK: - BaseCoordinator
    override func start() {
        showEditBookInfo()
    }

    // MARK: - Private Methods
    private func showEditBookInfo() {
        let viewController = EditBookInfoViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let reactor = EditBookInfoReactor(book: dependencies.book, bookRepository: bookRepository)
        viewController.reactor = reactor

        // onDismiss 콜백 설정
        viewController.onDismiss = { [weak self, weak reactor] isSaved in
            if isSaved {
                // 저장 성공 시 업데이트된 Book을 전달
                if let updatedBook = reactor?.currentState.updatedBook {
                    self?.resultRelay.accept(.bookInfoUpdated(updatedBook))
                } else {
                    // fallback: updatedBook이 없으면 취소로 처리
                    print("No updated book found after save")
                    self?.resultRelay.accept(.cancelled)
                }
            } else {
                self?.resultRelay.accept(.cancelled)
            }
        }

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen

        navigationController.present(navController, animated: true)
    }
}
