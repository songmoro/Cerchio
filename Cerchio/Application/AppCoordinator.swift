//
//  AppCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit

enum AppNavigationEvent: NavigationEventProtocol {
    case showLibrary
    case showProfile
    case showSearch
}

class AppCoordinator: BaseCoordinator<AppNavigationEvent> {
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
        super.init()
    }

    override func start(with dependencies: Void) {
        let tabBarController = CircleTabBarController()

        let libraryVC = LibraryViewController()
        libraryVC.tabBarItem = UITabBarItem(title: "서재", image: UIImage(systemName: "book"), tag: 0)

        tabBarController.viewControllers = [libraryVC]

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
}