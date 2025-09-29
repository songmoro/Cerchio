//
//  AppCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit

// MARK: - App Dependencies
struct AppDependencies {
    let dependencyAssembler: DependencyAssembler
    let serviceFactory: ServiceFactory

    init() {
        self.dependencyAssembler = DependencyAssembler()
        self.serviceFactory = dependencyAssembler.resolve(ServiceFactory.self)
    }
}

final class AppCoordinator: BaseCoordinator {
    private let window: UIWindow
    private let dependencies: AppDependencies

    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        self.dependencies = AppDependencies()
        super.init(navigationController: UINavigationController())
    }

    override func start() {
        showTabBar()
    }

    private func showTabBar() {
        let tabBarDependencies = TabBarDependencies(
            serviceFactory: dependencies.serviceFactory
        )
        let tabBarCoordinator = TabBarCoordinator(navigationController: navigationController)
        addChildCoordinator(tabBarCoordinator)

        tabBarCoordinator.start(with: tabBarDependencies)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

