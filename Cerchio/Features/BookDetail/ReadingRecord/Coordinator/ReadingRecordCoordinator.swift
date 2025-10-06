//
//  ReadingRecordCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import RxSwift
import RxRelay

final class ReadingRecordCoordinator: BaseCoordinator {
    struct Dependencies {
        let bookId: String
        let serviceFactory: ServiceFactory
    }

    enum Result {
        case recordSaved(String)
        case cancelled
    }

    // MARK: - Properties
    private let dependencies: Dependencies
    private let resultRelay = PublishRelay<Result>()

    var result: Observable<Result> {
        return resultRelay.asObservable()
    }

    // MARK: - Initialization
    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(navigationController: navigationController)
    }

    // MARK: - Coordinator
    override func start() {
        showReadingRecord()
    }

    // MARK: - Navigation
    private func showReadingRecord() {
        let reactor = ReadingRecordReactor(
            bookId: dependencies.bookId,
            serviceFactory: dependencies.serviceFactory
        )
        let readingRecordVC = ReadingRecordViewController()
        readingRecordVC.reactor = reactor

        readingRecordVC.onStartTimer = { [weak self] minutes in
            self?.showTimer(targetMinutes: minutes)
        }

        navigationController.pushViewController(readingRecordVC, animated: true)
    }

    private func showTimer(targetMinutes: Int) {
        let bookRepository = dependencies.serviceFactory.createBookRepository()

        bookRepository.getBook(by: dependencies.bookId)
            .take(1)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] realmBook in
                guard let self = self, let realmBook = realmBook else {
                    print("❌ Failed to load book for timer")
                    return
                }

                let book = realmBook.toBook()

                let timerCoordinator = ReadingTimerCoordinator(
                    navigationController: self.navigationController,
                    serviceFactory: self.dependencies.serviceFactory,
                    bookId: self.dependencies.bookId,
                    bookTitle: book.title,
                    targetMinutes: targetMinutes
                )

                self.addChildCoordinator(timerCoordinator)

                timerCoordinator.completion
                    .take(1)
                    .subscribe(onNext: { [weak self] in
                        guard let self = self else { return }
                        // Find and remove the timer coordinator
                        if let coordinator = self.childCoordinators.first(where: { $0 is ReadingTimerCoordinator }) {
                            self.removeChildCoordinator(coordinator)
                        }
                        self.finish(with: .recordSaved("Session completed"))
                    })
                    .disposed(by: self.disposeBag)

                timerCoordinator.start()
            })
            .disposed(by: disposeBag)
    }

    private func finish(with result: Result) {
        resultRelay.accept(result)
        finish()
    }
}
