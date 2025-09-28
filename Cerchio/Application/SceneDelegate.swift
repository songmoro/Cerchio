//
//  SceneDelegate.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        appCoordinator = AppCoordinator(windowScene: windowScene)
        appCoordinator?.start()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        appCoordinator?.finish()
        appCoordinator = nil
    }
}
