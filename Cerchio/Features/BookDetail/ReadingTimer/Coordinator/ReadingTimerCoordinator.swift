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
        super.init(navigationController: navigationController)
    }

    override func start() {
        let repository = serviceFactory.createReadingSessionRepository()
        let reactor = ReadingTimerReactor(
            bookId: bookId,
            bookTitle: bookTitle,
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

        // 사진 버튼 액션
        viewController.onPhotoTapped = { [weak self] in
            self?.showPhotoCapture()
        }

        // 문장 버튼 액션
        viewController.onQuoteTapped = { [weak self] in
            self?.showQuoteSave()
        }

        navigationController.pushViewController(viewController, animated: true)
    }

    private func showPhotoCapture() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true

        navigationController.present(imagePicker, animated: true)
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
                    print("✅ Quote saved from reading timer")
                case .cancelled:
                    print("❌ Quote save cancelled")
                }
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    private func finishSession() {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ReadingTimerCoordinator: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            print("❌ Failed to get image from picker")
            return
        }

        // Save photo
        let photoRepository = serviceFactory.createPhotoRepository()

        // Save image locally with unique name
        let imageName = UUID().uuidString
        if let imagePath = ImageStorageManager.shared.saveImage(selectedImage, withName: imageName) {
            let realmPhoto = RealmPhoto(
                bookId: bookId,
                localImagePath: imagePath
            )

            photoRepository.savePhoto(realmPhoto)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { _ in
                        print("✅ Photo saved from reading timer")
                    },
                    onError: { error in
                        print("❌ Failed to save photo: \(error.localizedDescription)")
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
