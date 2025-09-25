//
//  SceneDelegate.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        let tabBarController = CircleTabBarController()
//        tabBarController.setViewControllers([LibraryViewController()], animated: false)
        
//        let tabBarController = CustomTabBarController()
        let profileVC = ProfileViewController()
        profileVC.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person.circle"), tag: 0)
        let savedVC = SavedViewController()
        savedVC.tabBarItem = UITabBarItem(title: "Saved", image: UIImage(systemName: "bookmark"), tag: 1)
        let addVC = AddViewController()
        addVC.tabBarItem = UITabBarItem(title: "Add", image: UIImage(systemName: "plus"), tag: 2)
        let searchVC = SearchViewController()
        searchVC.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 3)
        let libraryVC = LibraryViewController()
        libraryVC.tabBarItem = UITabBarItem(title: "Library", image: UIImage(systemName: "book"), tag: 4)
        
        tabBarController.viewControllers = [profileVC, savedVC, addVC, searchVC, libraryVC]
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
}
