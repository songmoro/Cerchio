//
//  CircleTabBarController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/25/25.
//

import UIKit
import SnapKit
import SwiftUI

class CircleTabBarController: UITabBarController {
    override var viewControllers: [UIViewController]? {
        didSet {
            updateTabBarItems()
        }
    }

    override var selectedIndex: Int {
        didSet {
            circleTabBarViewModel.selectedIndex = selectedIndex
        }
    }

    // setViewControllers 메서드들 오버라이드로 자동 업데이트 보장
    override func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        updateTabBarItems()
    }

    // selectedViewController 설정 시에도 업데이트
    override var selectedViewController: UIViewController? {
        didSet {
            if let selectedVC = selectedViewController,
               let viewControllers = viewControllers,
               let index = viewControllers.firstIndex(of: selectedVC) {
                circleTabBarViewModel.selectedIndex = index
            }
        }
    }

    // 뷰 컨트롤러 추가/삭제 메서드들도 오버라이드
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
        delegate = self
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
            make.height.equalTo(68)
        }
        
//        let tabBarHeight: CGFloat = 83
//        additionalSafeAreaInsets.bottom = tabBarHeight
        
        circleTabBarViewModel.onTabSelected = { [weak self] index in
            self?.selectedIndex = index
        }
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

        // selectedIndex 범위 체크 후 설정
        if selectedIndex < viewControllers.count {
            circleTabBarViewModel.selectedIndex = selectedIndex
        } else {
            circleTabBarViewModel.selectedIndex = 0
            selectedIndex = 0
        }
    }
}

extension CircleTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("Did select: \(viewController.title ?? "Unknown")")
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("Should select: \(viewController.title ?? "Unknown")")
        return true
    }
}
