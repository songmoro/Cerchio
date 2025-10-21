//
//  QuoteListCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import RxSwift
import RxRelay
import ReactorKit

enum QuoteListResult {
    case quotesUpdated
    case dismissed
}

final class QuoteListCoordinator: BaseCoordinator {
    struct Dependencies {
        let bookId: String
        let serviceFactory: ServiceFactory
    }

    private let dependencies: Dependencies
    private let resultRelay = PublishRelay<QuoteListResult>()

    var result: Observable<QuoteListResult> {
        return resultRelay.asObservable()
    }

    init(navigationController: UINavigationController, dependencies: Dependencies) {
        self.dependencies = dependencies
        super.init(navigationController: navigationController)
    }

    override func start() {
        let reactor = QuoteListReactor(bookId: dependencies.bookId)
        let viewController = QuoteListViewController()
        viewController.reactor = reactor

        // 추가 버튼 액션
        viewController.onAddQuoteTapped = { [weak self] in
            self?.showQuoteEntry()
        }

        // 문장 수정 액션
        viewController.onQuoteEditTapped = { [weak self] quote in
            self?.showQuoteEdit(quote: quote)
        }

        navigationController.pushViewController(viewController, animated: true)
    }

    override func finish() {
        resultRelay.accept(.dismissed)
        super.finish()
    }

    // MARK: - Navigation
    private func showQuoteEntry() {
        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController,
            dependencies: QuoteSaveCoordinator.Dependencies(
                bookId: dependencies.bookId,
                serviceFactory: dependencies.serviceFactory
            )
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quoteSaved:
                    print(" Quote saved")
                    self?.resultRelay.accept(.quotesUpdated)
                    // QuoteListViewController의 reactor에 reload 트리거
                    if let quoteListVC = self?.navigationController.topViewController as? QuoteListViewController {
                        quoteListVC.reactor?.action.onNext(.loadQuotes)
                    }
                case .cancelled:
                    print("Quote save cancelled")
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }

    private func showQuoteEdit(quote: Quote) {
        let quoteSaveVC = QuoteSaveViewController(bookId: dependencies.bookId)
        quoteSaveVC.configureForEdit(quoteId: quote.id, quote: quote.quote, pageNumber: quote.pageNumber)

        let quoteRepository = dependencies.serviceFactory.createQuoteRepository()
        quoteSaveVC.setQuoteRepository(quoteRepository)

        // Rx event binding
        quoteSaveVC.events
            .subscribe(onNext: { [weak self] event in
                switch event {
                case .quoteSaved(let savedQuote):
                    quoteSaveVC.dismiss(animated: true) { [weak self] in
                        print(" Quote updated: \(savedQuote)")
                        self?.resultRelay.accept(.quotesUpdated)

                        // QuoteListViewController 새로고침
                        if let quoteListVC = self?.navigationController.topViewController as? QuoteListViewController {
                            quoteListVC.reactor?.action.onNext(.loadQuotes)
                        }
                    }
                case .cancelled:
                    quoteSaveVC.dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)

        let navController = UINavigationController(rootViewController: quoteSaveVC)
        navController.modalPresentationStyle = .pageSheet

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        navigationController.present(navController, animated: true)
    }
}
