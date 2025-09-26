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

        let libraryVC = LibraryViewController()
        libraryVC.tabBarItem = UITabBarItem(title: "서재", image: UIImage(systemName: "book"), tag: 0)

        tabBarController.viewControllers = [libraryVC]
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
    }
}
