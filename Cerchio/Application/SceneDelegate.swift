//
//  SceneDelegate.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var appCoordinator: AppCoordinator?
    private var windowScene: UIWindowScene?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        self.windowScene = windowScene
        startAppCoordinator()

        // 데이터 리셋 알림 구독
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataReset),
            name: .dataDidReset,
            object: nil
        )
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        NotificationCenter.default.removeObserver(self)
        appCoordinator?.finish()
        appCoordinator = nil
        windowScene = nil
    }

    // MARK: - Private Methods

    private func startAppCoordinator() {
        guard let windowScene = windowScene else { return }

        appCoordinator?.finish()
        appCoordinator = nil

        appCoordinator = AppCoordinator(windowScene: windowScene)
        appCoordinator?.start()
    }

    @objc private func handleDataReset() {
        // 모든 데이터가 리셋되었으므로 AppCoordinator를 새로 시작
        DispatchQueue.main.async { [weak self] in
            self?.startAppCoordinator()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dataDidReset = Notification.Name("com.cerchio.dataDidReset")
}
