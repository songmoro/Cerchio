//
//  AppCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit

final class AppCoordinator: BaseCoordinator {
    private let window: UIWindow

    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        super.init(navigationController: UINavigationController())
    }

    override func start() {
        showTabBar()
    }

    private func showTabBar() {
        let tabBarCoordinator = TabBarCoordinator(navigationController: navigationController)
        addChildCoordinator(tabBarCoordinator)
        
        tabBarCoordinator.start()
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

