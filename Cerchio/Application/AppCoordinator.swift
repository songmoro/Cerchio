//
//  AppCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit

class AppCoordinator: BaseCoordinator {
    private let window: UIWindow
    private var tabBarCoordinator: TabBarCoordinator?

    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        super.init(navigationController: UINavigationController())
    }

    override func start() {
        showMainInterface()
    }

    private func showMainInterface() {
        let tabBarCoordinator = TabBarCoordinator()
        self.tabBarCoordinator = tabBarCoordinator

        addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.start()

        window.rootViewController = tabBarCoordinator.getTabBarController()
        window.makeKeyAndVisible()
    }

    override func finish() {
        super.finish()
        tabBarCoordinator = nil
    }
}

