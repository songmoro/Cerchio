//
//  BaseTabBarController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit

protocol NavigationItemUpdatable: AnyObject {
    func updateNavigationItem(from viewController: UIViewController?)
}

class BaseTabBarController: UITabBarController, UITabBarControllerDelegate {

    private var isNavigationItemUpdateEnabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationItemIfNeeded()
    }

    open func setupTabBar() {
        tabBar.tintColor = .forestGreen
    }

    func enableNavigationItemUpdate(_ enabled: Bool) {
        isNavigationItemUpdateEnabled = enabled
        if enabled {
            updateNavigationItemIfNeeded()
        }
    }

    private func updateNavigationItemIfNeeded() {
        guard isNavigationItemUpdateEnabled else { return }
        updateNavigationItem(from: selectedViewController)
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateNavigationItemIfNeeded()
    }

    open func customizeNavigationItem(from viewController: UIViewController) {
    }
}

extension BaseTabBarController: NavigationItemUpdatable {
    func updateNavigationItem(from viewController: UIViewController?) {
        guard let viewController = viewController else { return }

        updateBasicNavigationItems(from: viewController)

        customizeNavigationItem(from: viewController)
    }

    private func updateBasicNavigationItems(from viewController: UIViewController) {
        navigationItem.title = viewController.navigationItem.title
        navigationItem.leftBarButtonItem = viewController.navigationItem.leftBarButtonItem
        navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem
        navigationItem.leftBarButtonItems = viewController.navigationItem.leftBarButtonItems
        navigationItem.rightBarButtonItems = viewController.navigationItem.rightBarButtonItems
        navigationItem.titleView = viewController.navigationItem.titleView
        navigationItem.prompt = viewController.navigationItem.prompt
    }
}
