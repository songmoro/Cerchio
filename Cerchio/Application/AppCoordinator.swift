//
//  AppCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit

class AppCoordinator: BaseCoordinator {
    private let window: UIWindow
    private var tabBarController: CircleTabBarController?

    init(windowScene: UIWindowScene) {
        self.window = UIWindow(windowScene: windowScene)
        super.init(navigationController: UINavigationController())
    }

    override func start() {
        showMainTabBar()
    }

    private func showMainTabBar() {
        let tabBarController = CircleTabBarController()
        self.tabBarController = tabBarController

        setupTabBarControllers(tabBarController)

        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }

    private func setupTabBarControllers(_ tabBarController: CircleTabBarController) {
        // 서재 탭 설정
        let libraryNav = UINavigationController()
        libraryNav.tabBarItem = UITabBarItem(
            title: "서재",
            image: UIImage(systemName: "books.vertical"),
            tag: 0
        )

        let libraryCoordinator = LibraryCoordinator(navigationController: libraryNav)
        addChildCoordinator(libraryCoordinator)
        libraryCoordinator.start()

        // 향후 추가될 탭들을 위한 확장 가능한 구조
        var viewControllers: [UIViewController] = [libraryNav]

        // TODO: 추가 탭들 (검색, 설정 등)
        // let searchNav = createSearchTab()
        // let settingsNav = createSettingsTab()
        // viewControllers.append(contentsOf: [searchNav, settingsNav])

        tabBarController.setViewControllers(viewControllers, animated: false)
    }

    // MARK: - Helper Methods for Future Tabs
    /*
    private func createSearchTab() -> UINavigationController {
        let searchNav = UINavigationController()
        searchNav.tabBarItem = UITabBarItem(
            title: "검색",
            image: UIImage(systemName: "magnifyingglass"),
            tag: 1
        )
        // SearchCoordinator 설정
        return searchNav
    }

    private func createSettingsTab() -> UINavigationController {
        let settingsNav = UINavigationController()
        settingsNav.tabBarItem = UITabBarItem(
            title: "설정",
            image: UIImage(systemName: "gearshape"),
            tag: 2
        )
        // SettingsCoordinator 설정
        return settingsNav
    }
    */
}

