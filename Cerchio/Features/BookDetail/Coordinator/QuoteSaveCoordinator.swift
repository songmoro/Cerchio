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
    }

    enum Result {
        case quoteSaved(String)
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
        showQuoteSave()
    }

    // MARK: - Navigation
    private func showQuoteSave() {
        let quoteSaveVC = QuoteSaveViewController(bookId: dependencies.bookId)
        quoteSaveVC.delegate = self

        // Repository 주입
        let quoteRepository = dependencies.serviceFactory.createQuoteRepository()
        quoteSaveVC.setQuoteRepository(quoteRepository)

        let quoteSaveNavController = UINavigationController(rootViewController: quoteSaveVC)
        quoteSaveNavController.modalPresentationStyle = .pageSheet

        // 페이지 시트 크기 설정
        if let sheet = quoteSaveNavController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        navigationController.present(quoteSaveNavController, animated: true)
    }

    private func finish(with result: Result) {
        resultRelay.accept(result)

        // 현재 표시된 모달 닫기
        if let presentedViewController = navigationController.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.finish()
            }
        } else {
            finish()
        }
    }
}

// MARK: - QuoteSaveViewControllerDelegate
extension QuoteSaveCoordinator: QuoteSaveViewControllerDelegate {
    func quoteSaveViewController(_ controller: QuoteSaveViewController, didSaveQuote quote: String) {
        finish(with: .quoteSaved(quote))
    }

    func quoteSaveViewControllerDidCancel(_ controller: QuoteSaveViewController) {
        finish(with: .cancelled)
    }
}