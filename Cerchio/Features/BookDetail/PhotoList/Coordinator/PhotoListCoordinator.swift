//
//  PhotoListCoordinator.swift
//  Cerchio
//
//  Created by Claude on 10/1/25.
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
        let reactor = PhotoListReactor(bookId: dependencies.bookId)
        let viewController = PhotoListViewController()
        viewController.reactor = reactor

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
