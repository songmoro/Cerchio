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

        // onChangeCover 콜백 설정
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

// MARK: - PHPickerViewControllerDelegate
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

            // 이미지 저장
            let imageName = ImageStorageManager.shared.generateUniqueImageName(for: self.dependencies.book.id)
            guard let imagePath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
                print("Failed to save custom cover image")
                return
            }

            // 메인 스레드에서 UI 업데이트
            DispatchQueue.main.async {
                if let editVC = picker.presentingViewController as? UINavigationController,
                   let viewController = editVC.viewControllers.first as? EditBookInfoViewController {
                    viewController.updateCoverImage(image, imagePath: imagePath)
                }
            }
        }
    }
}
