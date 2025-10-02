//
//  SettingsCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

enum SettingsNavigationEvent: NavigationEventProtocol {
    case navigateToLibrary
}

// MARK: - Settings Dependencies
struct SettingsDependencies {
    let serviceFactory: ServiceFactory
}

final class SettingsCoordinator: BaseCoordinator, Coordinatable {
    typealias Dependencies = SettingsDependencies

    private var dependencies: SettingsDependencies!

    // Callback for navigation to Library
    var onNavigateToLibrary: (() -> Void)?

    override func start() {
        fatalError("Use start(with dependencies:) instead")
    }

    func start(with dependencies: SettingsDependencies) {
        self.dependencies = dependencies
        showSettingsViewController()
        bindNavigationEvents()
    }

    private func showSettingsViewController() {
        let settingsViewController = SettingsViewController()

        // Repository 주입
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let settingsReactor = SettingsReactor(bookRepository: bookRepository)

        settingsViewController.coordinator = self
        settingsViewController.reactor = settingsReactor

        // Reset 완료 시 서재로 이동
        settingsReactor.state
            .map { $0.resetCompleted }
            .distinctUntilChanged()
            .filter { $0 == true }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.navigateToLibrary()
            })
            .disposed(by: disposeBag)

        navigationController.setViewControllers([settingsViewController], animated: false)
    }

    private func bindNavigationEvents() {
        navigationEvents
            .subscribe(onNext: { [weak self] event in
                self?.handleNavigationEvent(event)
            })
            .disposed(by: disposeBag)
    }

    private func handleNavigationEvent(_ event: NavigationEvent) {
        switch event {
        case .back:
            navigationController.popViewController(animated: true)
        case .close:
            navigationController.dismiss(animated: true)
        case .finished:
            finish()
        }
    }

    // MARK: - Navigation Methods

    func navigateToLibrary() {
        onNavigateToLibrary?()
    }
}
