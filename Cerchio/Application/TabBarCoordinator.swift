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

// MARK: - TabBar Dependencies
struct TabBarDependencies {
    let serviceFactory: ServiceFactory
}

final class TabBarCoordinator: BaseCoordinator, Coordinatable {
    typealias Dependencies = TabBarDependencies

    private var tabBarController: CircleTabBarController!
    private var dependencies: TabBarDependencies!

    override init(navigationController: UINavigationController) {
        super.init(navigationController: navigationController)
    }

    override func start() {
        fatalError("Use start(with dependencies:) instead")
    }

    func start(with dependencies: TabBarDependencies) {
        self.dependencies = dependencies
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

        // 서재 탭 설정 - 단순한 ViewController (내부에서 LibraryCoordinator 사용)
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
            title: AppConstants.TabBar.Titles.library,
            image: UIImage(systemName: AppConstants.TabBar.SystemImages.library),
            tag: AppConstants.TabBar.Tags.library
        )
        libraryViewController.navigationItem.title = AppConstants.TabBar.Titles.library

        // 서재에서 네비게이션 처리를 위한 핸들러 설정
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
        let bookDetailDependencies = BookDetailDependencies(
            serviceFactory: dependencies.serviceFactory,
            book: book
        )
        let bookDetailCoordinator = BookDetailCoordinator(navigationController: navigationController)
        addChildCoordinator(bookDetailCoordinator)
        bookDetailCoordinator.start(with: bookDetailDependencies)
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

    private func createSearchTabViewController() -> UIViewController {
        let searchViewController = SearchViewController()
        let bookSearchService = dependencies.serviceFactory.createBookSearchService()
        let searchReactor = SearchReactor(bookSearchService: bookSearchService)

        searchViewController.reactor = searchReactor
        searchViewController.tabBarItem = UITabBarItem(
            title: AppConstants.TabBar.Titles.search,
            image: UIImage(systemName: AppConstants.TabBar.SystemImages.search),
            tag: AppConstants.TabBar.Tags.search
        )
        searchViewController.navigationItem.title = AppConstants.TabBar.Titles.search

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
            title: AppConstants.TabBar.Titles.search,
            image: UIImage(systemName: AppConstants.TabBar.SystemImages.search),
            tag: AppConstants.TabBar.Tags.search
        )

        // TODO: SearchCoordinator 구현 시 활성화
        // let searchCoordinator = SearchCoordinator(navigationController: searchNav)
        // addChildCoordinator(searchCoordinator)
        // searchCoordinator.start()

        return searchNav
    }
}
