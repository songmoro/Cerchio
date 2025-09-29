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
    }

    private func updateNavigationTitle() {
        guard let viewControllers = viewControllers,
              selectedIndex < viewControllers.count else { return }

        let selectedViewController = viewControllers[selectedIndex]
        navigationItem.title = selectedViewController.navigationItem.title
    }
}
