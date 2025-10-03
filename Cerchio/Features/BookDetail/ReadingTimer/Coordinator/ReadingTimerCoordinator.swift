//
//  ReadingTimerCoordinator.swift
//  Cerchio
//
//  Created by Claude on 10/3/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ReadingTimerCoordinator: BaseCoordinator {

    private let serviceFactory: ServiceFactory
    private let bookId: String
    private let targetMinutes: Int

    private let completionRelay = PublishRelay<Void>()
    var completion: Observable<Void> {
        completionRelay.asObservable()
    }

    init(
        navigationController: UINavigationController,
        serviceFactory: ServiceFactory,
        bookId: String,
        targetMinutes: Int
    ) {
        self.serviceFactory = serviceFactory
        self.bookId = bookId
        self.targetMinutes = targetMinutes
        super.init(navigationController: navigationController)
    }

    override func start() {
        let repository = serviceFactory.createReadingSessionRepository()
        let reactor = ReadingTimerReactor(
            bookId: bookId,
            targetMinutes: targetMinutes,
            sessionRepository: repository
        )

        let viewController = ReadingTimerViewController()
        viewController.reactor = reactor

        // ViewController 완료 이벤트 구독
        viewController.completion
            .subscribe(onNext: { [weak self] in
                self?.finishSession()
                self?.completionRelay.accept(())
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(viewController, animated: true)
    }

    private func finishSession() {
        navigationController.popViewController(animated: true)
    }
}
