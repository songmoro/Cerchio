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

    func sceneDidBecomeActive(_ scene: UIScene) {
        // 앱이 활성화될 때 활성 타이머 세션 확인 및 복원
        checkAndRestoreActiveTimerSession()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // 위젯/알림에서 딥링크로 진입 시 처리
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
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

    private func checkAndRestoreActiveTimerSession() {
        // AppCoordinator가 이미 세션 복원을 처리하고 있으므로
        // 여기서는 추가 처리 불필요
        // AppCoordinator.start()에서 자동으로 체크됨
    }

    private func handleDeepLink(_ url: URL) {
        print("[SceneDelegate] 🔗 Handling deeplink: \(url.absoluteString)")

        // 딥링크 스킴: cerchio://timer/{bookId}
        guard url.scheme == "cerchio" else {
            print("[SceneDelegate] ❌ Invalid scheme: \(url.scheme ?? "nil")")
            return
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 1 else {
            print("[SceneDelegate] ❌ Invalid path components")
            return
        }

        let action = pathComponents[0]

        switch action {
        case "timer":
            // 타이머 화면으로 이동 (활성 세션이 있으면 AppCoordinator에서 자동 복원)
            checkAndRestoreActiveTimerSession()

        default:
            print("[SceneDelegate] ⚠️ Unknown deeplink action: \(action)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dataDidReset = Notification.Name("com.cerchio.dataDidReset")
}
