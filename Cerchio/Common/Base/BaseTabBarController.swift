//
//  BaseTabBarController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit

// MARK: - NavigationItemUpdatable Protocol
protocol NavigationItemUpdatable: AnyObject {
    func updateNavigationItem(from viewController: UIViewController?)
}

// MARK: - Base Tab Bar Controller
class BaseTabBarController: UITabBarController, UITabBarControllerDelegate {

    // MARK: - Properties
    private var isNavigationItemUpdateEnabled: Bool = true

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationItemIfNeeded()
    }

    // MARK: - Setup
    open func setupTabBar() {
        // 서브클래스에서 오버라이드하여 탭바 스타일 설정
        tabBar.tintColor = .forestGreen
    }

    // MARK: - Navigation Item Management
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

    // MARK: - UITabBarControllerDelegate
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateNavigationItemIfNeeded()
    }

    // MARK: - Customization Points
    open func customizeNavigationItem(from viewController: UIViewController) {
        // 서브클래스에서 오버라이드하여 추가 커스터마이징
    }

    open func shouldUpdateNavigationItem(for viewController: UIViewController) -> Bool {
        // 서브클래스에서 오버라이드하여 업데이트 조건 설정
        return true
    }
}

// MARK: - NavigationItemUpdatable Implementation
extension BaseTabBarController: NavigationItemUpdatable {
    func updateNavigationItem(from viewController: UIViewController?) {
        guard let viewController = viewController else { return }

        // 기본 네비게이션 아이템 업데이트
        updateBasicNavigationItems(from: viewController)

        // 서브클래스에서 추가 커스터마이징 가능
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
