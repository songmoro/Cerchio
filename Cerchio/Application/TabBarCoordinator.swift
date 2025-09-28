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
    private var tabBarController: CircleTabBarController!

    override init(navigationController: UINavigationController) {
        super.init(navigationController: navigationController)
    }

    override func start() {
        setupTabBarController()
        bindNavigationEvents()
    }

    private func createTabBarController() -> CircleTabBarController {
        return CircleTabBarController()
    }

    private func setupTabBarController() {
        tabBarController = createTabBarController()

        // 탭바 컨트롤러를 네비게이션 컨트롤러에 설정
        navigationController.setViewControllers([tabBarController], animated: false)

        // 서재 탭 설정 - 단순한 ViewController만 생성 (내부 네비게이션 없음)
        let libraryViewController = createLibraryTab()

        // 향후 추가될 탭들을 위한 확장 가능한 구조
        var viewControllers: [UIViewController] = [libraryViewController]

        // 검색 탭 설정
        let searchViewController = createSearchTabViewController()
        viewControllers.append(searchViewController)

        tabBarController.setViewControllers(viewControllers, animated: false)
    }

    private func createLibraryTab() -> UIViewController {
        let libraryViewController = LibraryViewController()
        let libraryReactor = LibraryReactor()

        libraryViewController.reactor = libraryReactor
        libraryViewController.tabBarItem = UITabBarItem(
            title: "서재",
            image: UIImage(systemName: "books.vertical"),
            tag: 0
        )
        libraryViewController.navigationItem.title = "서재"

        // 서재 코디네이터는 별도로 생성하지 않고, 직접 네비게이션 처리
        setupLibraryNavigation(libraryViewController)

        return libraryViewController
    }

    private func setupLibraryNavigation(_ libraryViewController: LibraryViewController) {
        // LibraryViewController에서 도서 선택 시 BookDetail로 네비게이션
        libraryViewController.bookSelectionHandler = { [weak self] book in
            self?.navigateToBookDetail(book: book)
        }
    }

    private func navigateToBookDetail(book: Book) {
        let bookDetailViewController = BookDetailViewController()
        let bookDetailReactor = BookDetailReactor(book: book)
        bookDetailViewController.reactor = bookDetailReactor

        push(bookDetailViewController)
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

    private func createSearchTabViewController() -> UIViewController {
        let searchViewController = SearchViewController()
        let searchReactor = SearchReactor()

        searchViewController.reactor = searchReactor
        searchViewController.tabBarItem = UITabBarItem(
            title: "검색",
            image: UIImage(systemName: "magnifyingglass"),
            tag: 1
        )
        searchViewController.navigationItem.title = "검색"

        // 검색 결과에서 도서를 라이브러리에 추가하는 로직
        setupSearchNavigation(searchViewController)

        return searchViewController
    }

    private func setupSearchNavigation(_ searchViewController: SearchViewController) {
        // 향후 검색 결과에서 도서 상세로 이동하는 로직 추가 가능
        // 현재는 "담기" 버튼 동작만 처리됨
    }

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
