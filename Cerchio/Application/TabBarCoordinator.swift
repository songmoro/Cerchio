//
//  TabBarCoordinator.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import ReactorKit

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
    }

    private func createTabBarController() -> CircleTabBarController {
        return CircleTabBarController()
    }

    private func setupTabBarController() {
        tabBarController = createTabBarController()
        navigationController.setViewControllers([tabBarController], animated: false)

        let libraryViewController = createLibraryTab()
        let searchViewController = createSearchTab()
        let settingsViewController = createSettingsTab()
        let viewControllers: [UIViewController] = [libraryViewController, searchViewController, settingsViewController]

        tabBarController.setViewControllers(viewControllers, animated: false)
    }

    private func createLibraryTab() -> UIViewController {
        let libraryViewController = LibraryViewController()

        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let tagRepository = dependencies.serviceFactory.createTagRepository()
        let quoteRepository = dependencies.serviceFactory.createQuoteRepository()
        let photoRepository = dependencies.serviceFactory.createPhotoRepository()
        let libraryReactor = LibraryReactor(bookRepository: bookRepository, tagRepository: tagRepository)
        libraryViewController.setBookRepository(bookRepository)
        libraryViewController.setTagRepository(tagRepository)
        libraryViewController.setQuoteRepository(quoteRepository)
        libraryViewController.setPhotoRepository(photoRepository)

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
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let searchHistoryRepository = dependencies.serviceFactory.createSearchHistoryRepository()
        let searchReactor = SearchReactor(
            bookSearchService: bookSearchService,
            bookRepository: bookRepository,
            searchHistoryRepository: searchHistoryRepository
        )

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

    private func createSettingsTab() -> UIViewController {
        let settingsViewController = SettingsViewController()
        let bookRepository = dependencies.serviceFactory.createBookRepository()
        let settingsReactor = SettingsReactor(bookRepository: bookRepository)

        settingsViewController.reactor = settingsReactor
        settingsViewController.tabBarItem = UITabBarItem(
            title: AppConstants.TabBar.Titles.settings,
            image: UIImage(systemName: AppConstants.TabBar.SystemImages.settings),
            tag: AppConstants.TabBar.Tags.settings
        )
        settingsViewController.navigationItem.title = AppConstants.TabBar.Titles.settings

        settingsReactor.state
            .map { $0.resetCompleted }
            .distinctUntilChanged()
            .filter { $0 == true }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tabBarController.selectedIndex = AppConstants.TabBar.Tags.library
            })
            .disposed(by: disposeBag)

        return settingsViewController
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
        searchViewController.onBookSaved = { [weak self] book in
            self?.navigateToBookDetail(book: book)
        }
    }
}
