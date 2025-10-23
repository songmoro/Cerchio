//
//  QuoteShareCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import RxSwift
import RxRelay

final class QuoteShareCoordinator: BaseCoordinator {
    struct Dependencies {
        let quoteData: QuoteShareData
    }

    enum Result {
        case imageExported(UIImage)
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
        showQuoteShare()
    }

    private func showQuoteShare() {
        let reactor = QuoteShareReactor(quoteData: dependencies.quoteData)
        let quoteShareVC = QuoteShareViewController()
        quoteShareVC.reactor = reactor

        quoteShareVC.navigationEvents
            .subscribe(onNext: { [weak self] event in
                switch event {
                case .close:
                    self?.finish(with: .cancelled)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        quoteShareVC.imageExported
            .subscribe(onNext: { [weak self] image in
                self?.finish(with: .imageExported(image))
            })
            .disposed(by: disposeBag)

        navigationController.pushViewController(quoteShareVC, animated: true)
    }

    private func finish(with result: Result) {
        resultRelay.accept(result)
        navigationController.popViewController(animated: true)
        finish()
    }
}
