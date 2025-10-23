//
//  CircleTabBarController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/25/25.
//

import UIKit
import SnapKit
import SwiftUI

class CircleTabBarController: BaseTabBarController {
    override var viewControllers: [UIViewController]? {
        didSet {
            updateTabBarItems()
        }
    }

    override var selectedIndex: Int {
        didSet {
            circleTabBarViewModel.selectedIndex = selectedIndex
            updateNavigationTitle()
        }
    }

    override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        updateTabBarItems()
    }

    override var selectedViewController: UIViewController? {
        didSet {
            if let selectedVC = selectedViewController,
               let viewControllers = viewControllers,
               let index = viewControllers.firstIndex(of: selectedVC) {
                circleTabBarViewModel.selectedIndex = index
            }
        }
    }

    override func addChild(_ childController: UIViewController) {
        super.addChild(childController)
        DispatchQueue.main.async { [weak self] in
            self?.updateTabBarItems()
        }
    }

    override func removeFromParent() {
        super.removeFromParent()
        DispatchQueue.main.async { [weak self] in
            self?.updateTabBarItems()
        }
    }
    
    private var swiftUITabBarHostingController: UIHostingController<CircleTabBarView>!
    private var circleTabBarViewModel = CircleTabBarViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomTabBar()
        tabBar.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavigationTitle()
    }
    
    private func setupCustomTabBar() {
        let swiftUITabBar = CircleTabBarView(viewModel: circleTabBarViewModel)
        swiftUITabBarHostingController = UIHostingController(rootView: swiftUITabBar)
        
        addChild(swiftUITabBarHostingController)
        view.addSubview(swiftUITabBarHostingController.view)
        
        swiftUITabBarHostingController.didMove(toParent: self)
        swiftUITabBarHostingController.view.backgroundColor = .clear
        
        swiftUITabBarHostingController.view.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(CircleTabBarConstants.Dimensions.hostingControllerHeight)
        }
        
        circleTabBarViewModel.onTabSelected = { [weak self] index in
            self?.selectedIndex = index
        }

        updateNavigationTitle()
    }
    
    private func updateTabBarItems() {
        guard let viewControllers = viewControllers, !viewControllers.isEmpty else {
            circleTabBarViewModel.tabItems = []
            return
        }

        let tabItems = viewControllers.map { viewController in
            CircleTabBarItemModel(
                title: viewController.tabBarItem.title ?? "",
                image: viewController.tabBarItem.image,
                tag: viewController.tabBarItem.tag
            )
        }

        circleTabBarViewModel.tabItems = tabItems

        if selectedIndex < viewControllers.count {
            circleTabBarViewModel.selectedIndex = selectedIndex
        } else {
            circleTabBarViewModel.selectedIndex = 0
            selectedIndex = 0
        }

        updateNavigationTitle()
    }

    private func updateNavigationTitle() {
        guard let viewControllers = viewControllers,
              selectedIndex < viewControllers.count else { return }

        let selectedViewController = viewControllers[selectedIndex]

        navigationItem.title = selectedViewController.navigationItem.title

        updateNavigationBarButtons(for: selectedViewController)
    }

    private func updateNavigationBarButtons(for viewController: UIViewController) {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil

        if let libraryVC = viewController as? LibraryViewController {
            setupLibraryNavigationBar(libraryVC)
        } else if viewController is SearchViewController {
            setupSearchNavigationBar()
        } else if let bookDetailVC = viewController as? BookDetailViewController {
            setupBookDetailNavigationBar(bookDetailVC)
        }
    }

    private func setupLibraryNavigationBar(_ libraryVC: LibraryViewController) {
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: CircleTabBarConstants.SystemImages.filter),
            style: .plain,
            target: nil,
            action: nil
        )

        let editButton = UIBarButtonItem(
            title: String(localized: .actionEdit),
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItems = [editButton, filterButton]

        libraryVC.setEditButton(editButton)
        libraryVC.setFilterButton(filterButton)
    }

    private func setupSearchNavigationBar() {
    }

    private func setupBookDetailNavigationBar(_ bookDetailVC: BookDetailViewController) {
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: CircleTabBarConstants.SystemImages.heart),
            style: .plain,
            target: nil,
            action: nil
        )

        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: CircleTabBarConstants.SystemImages.trash),
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]

        bookDetailVC.setFavoriteButton(favoriteButton)
        bookDetailVC.setDeleteButton(deleteButton)
    }
}
