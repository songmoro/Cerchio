//
//  PhotoListCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import UIKit
import RxSwift
import RxRelay
import ReactorKit

enum PhotoListResult {
    case photosUpdated
    case dismissed
}

final class PhotoListCoordinator: BaseCoordinator {
    struct Dependencies {
        let bookId: String
        let serviceFactory: ServiceFactory
        let onAddPhotoTapped: () -> Void
    }

    private let dependencies: Dependencies
    private let resultRelay = PublishRelay<PhotoListResult>()

    var result: Observable<PhotoListResult> {
        return resultRelay.asObservable()
    }

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(navigationController: navigationController)
    }

    override func start() {
        let service = PhotoListService(serviceFactory: dependencies.serviceFactory)
        let reactor = PhotoListReactor(bookId: dependencies.bookId, service: service)
        let viewController = PhotoListViewController()
        viewController.reactor = reactor
        viewController.setService(service)

        // 추가 버튼 액션
        viewController.onAddPhotoTapped = { [weak self] in
            self?.dependencies.onAddPhotoTapped()
            self?.resultRelay.accept(.photosUpdated)
        }

        // 사진 삭제 액션
        viewController.onPhotosDeleted = { [weak self] in
            self?.resultRelay.accept(.photosUpdated)
        }

        navigationController.pushViewController(viewController, animated: true)
    }

    override func finish() {
        resultRelay.accept(.dismissed)
        super.finish()
    }
}
