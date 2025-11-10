//
//  ReadingTimerCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import RxSwift
import RxCocoa

final class ReadingTimerCoordinator: BaseCoordinator {

    private let serviceFactory: ServiceFactory
    private let bookId: String
    private let bookTitle: String
    private let targetMinutes: Int
    private let restoredSession: TimerSessionManager.ActiveSession?
    private var photoCompletionHandler: ((UIImage) -> Void)?

    private let completionRelay = PublishRelay<Void>()
    var completion: Observable<Void> {
        completionRelay.asObservable()
    }

    init(
        navigationController: UINavigationController,
        serviceFactory: ServiceFactory,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int
    ) {
        self.serviceFactory = serviceFactory
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.targetMinutes = targetMinutes
        self.restoredSession = nil
        super.init(navigationController: navigationController)
    }

    init(
        navigationController: UINavigationController,
        serviceFactory: ServiceFactory,
        bookId: String,
        bookTitle: String,
        session: TimerSessionManager.ActiveSession
    ) {
        self.serviceFactory = serviceFactory
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.targetMinutes = session.targetMinutes
        self.restoredSession = session
        super.init(navigationController: navigationController)
    }

    override func start() {
        let viewController = createViewController()
        navigationController.pushViewController(viewController, animated: true)
    }

    func createViewController() -> ReadingTimerViewController {
        let repository = serviceFactory.createReadingSessionRepository()
        let reactor: ReadingTimerReactor

        if let session = restoredSession {
            reactor = ReadingTimerReactor(
                session: session,
                sessionRepository: repository
            )
        } else {
            reactor = ReadingTimerReactor(
                bookId: bookId,
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionRepository: repository
            )
        }

        let viewController = ReadingTimerViewController()
        viewController.reactor = reactor

        viewController.completion
            .subscribe(onNext: { [weak self] in
                self?.finishSession()
                self?.completionRelay.accept(())
            })
            .disposed(by: disposeBag)

        viewController.onPhotoTapped = { [weak self] in
            self?.showPhotoCapture()
        }

        viewController.onQuoteTapped = { [weak self] in
            self?.showQuoteSave()
        }

        return viewController
    }

    private func showPhotoCapture() {
        guard let topViewController = navigationController.topViewController else { return }

        CameraPermissionManager.shared.handleCameraPermission(from: topViewController) { [weak self] granted in
            guard granted else {
                return
            }

            let cameraVC = CameraViewController()
            cameraVC.delegate = self
            cameraVC.modalPresentationStyle = .fullScreen

            self?.photoCompletionHandler = { [weak self] image in
                self?.savePhoto(image)
            }

            self?.navigationController.present(cameraVC, animated: true)
        }
    }

    private func savePhoto(_ image: UIImage) {
        let photoRepository = serviceFactory.createPhotoRepository()

        let imageName = UUID().uuidString
        if let imagePath = ImageStorageManager.shared.saveImage(image, withName: imageName) {
            let realmPhoto = RealmPhoto(
                bookId: bookId,
                localImagePath: imagePath
            )

            photoRepository.savePhoto(realmPhoto)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { _ in
                    },
                    onError: { error in
                        print(" Failed to save photo: \(error.localizedDescription)")
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    private func showQuoteSave() {
        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController,
            dependencies: QuoteSaveCoordinator.Dependencies(
                bookId: bookId,
                serviceFactory: serviceFactory
            )
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }

                if let coordinator = self.childCoordinators.first(where: { $0 is QuoteSaveCoordinator }) {
                    self.removeChildCoordinator(coordinator)
                }

                switch result {
                case .quoteSaved:
                    break
                case .cancelled:
                    break
                }
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    private func finishSession() {
        navigationController.popViewController(animated: true)
    }
}

extension ReadingTimerCoordinator: CameraViewControllerDelegate {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            self?.photoCompletionHandler?(image)
            self?.photoCompletionHandler = nil
        }
    }

    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        controller.dismiss(animated: true) { [weak self] in
            self?.photoCompletionHandler = nil
        }
    }
}
