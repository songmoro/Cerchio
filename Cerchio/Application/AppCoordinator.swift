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
        // NavigationController를 루트로 설정
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        // TabBarController를 NavigationController에 설정
        let tabBarCoordinator = TabBarCoordinator(navigationController: navigationController)
        self.tabBarCoordinator = tabBarCoordinator

        addChildCoordinator(tabBarCoordinator)
        tabBarCoordinator.start()
    }

    override func finish() {
        super.finish()
        tabBarCoordinator = nil
    }
}

