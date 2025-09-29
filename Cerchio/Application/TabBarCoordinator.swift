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
        navigationController.setViewControllers([tabBarController], animated: false)
        
        let libraryViewController = createLibraryTab()
        let searchViewController = createSearchTab()
        let viewControllers: [UIViewController] = [libraryViewController, searchViewController]

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

        setupLibraryNavigation(libraryViewController)

        return libraryViewController
    }
    
    private func createSearchTab() -> UIViewController {
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
        setupSearchNavigation(searchViewController)

        return searchViewController
    }

    private func setupLibraryNavigation(_ libraryViewController: LibraryViewController) {
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

    private func setupSearchNavigation(_ searchViewController: SearchViewController) {
        // 향후 검색 결과에서 도서 상세로 이동하는 로직 추가 가능
        // 현재는 "담기" 버튼 동작만 처리됨
    }
}
