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

        navigationController.pushViewController(readingRecordVC, animated: true)
    }

    private func finish(with result: Result) {
        resultRelay.accept(result)
        finish()
    }
}
