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
        // 앱 초기 시작 시 네비게이션 바 설정
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

        // 탭 아이템 업데이트 후 네비게이션 바도 업데이트
        updateNavigationTitle()
    }

    private func updateNavigationTitle() {
        guard let viewControllers = viewControllers,
              selectedIndex < viewControllers.count else { return }

        let selectedViewController = viewControllers[selectedIndex]

        // 네비게이션 타이틀 업데이트
        navigationItem.title = selectedViewController.navigationItem.title

        // 네비게이션 바 버튼들 업데이트
        updateNavigationBarButtons(for: selectedViewController)
    }

    private func updateNavigationBarButtons(for viewController: UIViewController) {
        // 기본적으로 모든 버튼 제거
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil

        // 뷰 컨트롤러 타입에 따라 적절한 네비게이션 바 설정
        if let libraryVC = viewController as? LibraryViewController {
            setupLibraryNavigationBar(libraryVC)
        } else if viewController is SearchViewController {
            setupSearchNavigationBar()
        } else if let bookDetailVC = viewController as? BookDetailViewController {
            setupBookDetailNavigationBar(bookDetailVC)
        }
    }

    private func setupLibraryNavigationBar(_ libraryVC: LibraryViewController) {
        // 필터 버튼
        let filterButton = UIBarButtonItem(
            image: UIImage(systemName: CircleTabBarConstants.SystemImages.filter),
            style: .plain,
            target: nil,
            action: nil
        )

        // 편집 버튼
        let editButton = UIBarButtonItem(
            title: String(localized: .actionEdit),
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItems = [editButton, filterButton]

        // LibraryViewController의 버튼 참조 및 Rx 바인딩 설정
        libraryVC.setEditButton(editButton)
        libraryVC.setFilterButton(filterButton)
    }

    private func setupSearchNavigationBar() {
        // 검색 화면에서는 네비게이션 바 버튼 없음
    }

    private func setupBookDetailNavigationBar(_ bookDetailVC: BookDetailViewController) {
        // 즐겨찾기 버튼
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: CircleTabBarConstants.SystemImages.heart),
            style: .plain,
            target: nil,
            action: nil
        )

        // 삭제 버튼
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: CircleTabBarConstants.SystemImages.trash),
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]

        // BookDetailViewController에게 버튼 참조 전달 (Rx 바인딩은 VC에서 처리)
        bookDetailVC.setFavoriteButton(favoriteButton)
        bookDetailVC.setDeleteButton(deleteButton)
    }
}
