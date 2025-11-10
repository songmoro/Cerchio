//
//  QuoteSaveCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import RxSwift
import RxRelay

final class QuoteSaveCoordinator: BaseCoordinator {
    struct Dependencies {
        let bookId: String
        let serviceFactory: ServiceFactory
        let existingQuote: String?
        let existingPageNumber: Int?

        init(bookId: String, serviceFactory: ServiceFactory, existingQuote: String? = nil, existingPageNumber: Int? = nil) {
            self.bookId = bookId
            self.serviceFactory = serviceFactory
            self.existingQuote = existingQuote
            self.existingPageNumber = existingPageNumber
        }
    }

    enum Result {
        case quoteSaved(String)
        case cancelled
    }

    private let dependencies: Dependencies
    private let resultRelay = PublishRelay<Result>()

    var result: Observable<Result> {
        return resultRelay.asObservable()
    }

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(navigationController: navigationController)
    }

    override func start() {
        showQuoteSave()
    }

    private func showQuoteSave() {
        let quoteSaveVC = QuoteSaveViewController(
            bookId: dependencies.bookId,
            existingQuote: dependencies.existingQuote,
            existingPageNumber: dependencies.existingPageNumber
        )

        let quoteRepository = dependencies.serviceFactory.createQuoteRepository()
        quoteSaveVC.setQuoteRepository(quoteRepository)

        quoteSaveVC.events
            .subscribe(onNext: { [weak self] event in
                switch event {
                case .quoteSaved(let quote):
                    self?.finish(with: .quoteSaved(quote))
                case .cancelled:
                    self?.finish(with: .cancelled)
                }
            })
            .disposed(by: disposeBag)

        let quoteSaveNavController = UINavigationController(rootViewController: quoteSaveVC)
        quoteSaveNavController.modalPresentationStyle = .pageSheet

        quoteSaveNavController.isModalInPresentation = true

        if let sheet = quoteSaveNavController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        navigationController.present(quoteSaveNavController, animated: true)
    }

    private func finish(with result: Result) {
        resultRelay.accept(result)

        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.finish()
            }
        } else {
            finish()
        }
    }
}
