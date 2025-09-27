//
//  TabBarCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa

enum TabBarNavigationEvent: NavigationEventProtocol {
    case librarySelected
    case searchSelected
    case settingsSelected
}

final class TabBarCoordinator: BaseCoordinator {
    private var tabBarController: CircleTabBarController

    init() {
        self.tabBarController = CircleTabBarController()
        super.init(navigationController: UINavigationController())
    }

    override func start() {
        setupTabBarController()
        bindNavigationEvents()
    }

    func getTabBarController() -> CircleTabBarController {
        return tabBarController
    }

    private func setupTabBarController() {
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

        // 임시로 빈 뷰컨트롤러 추가 (향후 다른 탭들로 대체)
        let placeholderVC = createPlaceholderTab(title: "검색", systemImage: "magnifyingglass", tag: 1)
        viewControllers.append(placeholderVC)

        tabBarController.setViewControllers(viewControllers, animated: false)
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
        case .back, .close, .finished:
            finish()
        }
    }

    // MARK: - Helper Methods

    private func createPlaceholderTab(title: String, systemImage: String, tag: Int) -> UIViewController {
        let nav = UINavigationController()
        let placeholderVC = UIViewController()
        placeholderVC.view.backgroundColor = .systemBackground
        placeholderVC.navigationItem.title = title

        // TODO 라벨 추가
        let label = UILabel()
        label.text = "\(title) - 준비 중"
        label.textAlignment = .center
        label.font = .custom(weight: .medium, size: 18)
        label.textColor = .secondaryLabel

        placeholderVC.view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: placeholderVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: placeholderVC.view.centerYAnchor)
        ])

        nav.setViewControllers([placeholderVC], animated: false)
        nav.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: systemImage),
            tag: tag
        )

        return nav
    }

    // MARK: - Future Tab Creation Methods

    private func createSearchTab() -> UINavigationController {
        let searchNav = UINavigationController()
        searchNav.tabBarItem = UITabBarItem(
            title: "검색",
            image: UIImage(systemName: "magnifyingglass"),
            tag: 1
        )

        // TODO: SearchCoordinator 구현 시 활성화
        // let searchCoordinator = SearchCoordinator(navigationController: searchNav)
        // addChildCoordinator(searchCoordinator)
        // searchCoordinator.start()

        return searchNav
    }

    private func createSettingsTab() -> UINavigationController {
        let settingsNav = UINavigationController()
        settingsNav.tabBarItem = UITabBarItem(
            title: "설정",
            image: UIImage(systemName: "gearshape"),
            tag: 2
        )

        // TODO: SettingsCoordinator 구현 시 활성화
        // let settingsCoordinator = SettingsCoordinator(navigationController: settingsNav)
        // addChildCoordinator(settingsCoordinator)
        // settingsCoordinator.start()

        return settingsNav
    }
}
