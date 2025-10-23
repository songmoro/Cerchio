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
import PhotosUI

final class EditBookInfoCoordinator: BaseCoordinator {
    enum Result {
        case bookInfoUpdated(Book)
        case cancelled
    }

    struct Dependencies {
        let book: Book
        let serviceFactory: ServiceFactory
    }

    private let dependencies: Dependencies
    private let resultRelay = PublishRelay<Result>()

    var result: Observable<Result> {
        resultRelay.asObservable()
    }

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(navigationController: navigationController)
    }

    override func start() {
        showEditBookInfo()
    }

    private func showEditBookInfo() {
        let viewController = EditBookInfoViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let reactor = EditBookInfoReactor(book: dependencies.book, bookRepository: bookRepository)
        viewController.reactor = reactor

        viewController.onDismiss = { [weak self, weak reactor] isSaved in
            if isSaved {
                if let updatedBook = reactor?.currentState.updatedBook {
                    self?.resultRelay.accept(.bookInfoUpdated(updatedBook))
                } else {
                    self?.resultRelay.accept(.cancelled)
                }
            } else {
                self?.resultRelay.accept(.cancelled)
            }
        }

        viewController.onChangeCover = { [weak self, weak viewController] in
            self?.showImagePicker(from: viewController)
        }

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen

        navigationController.present(navController, animated: true)
    }

    private func showImagePicker(from viewController: EditBookInfoViewController?) {
        guard let viewController = viewController else { return }

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }
}

extension EditBookInfoCoordinator: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let result = results.first else { return }

        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            guard let self = self,
                  let image = object as? UIImage else {
                if let error = error {
                    print("Failed to load image: \(error)")
                }
                return
            }

            let imageName = ImageStorageManager.shared.generateUniqueImageName(for: self.dependencies.book.id)
            guard let imagePath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
                return
            }

            DispatchQueue.main.async {
                if let editVC = picker.presentingViewController as? UINavigationController,
                   let viewController = editVC.viewControllers.first as? EditBookInfoViewController {
                    viewController.updateCoverImage(image, imagePath: imagePath)
                }
            }
        }
    }
}
