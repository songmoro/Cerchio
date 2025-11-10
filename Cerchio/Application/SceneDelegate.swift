//
//  SceneDelegate.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit
import RxSwift

final class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISceneDelegate {
    private var appCoordinator: AppCoordinator?
    private var windowScene: UIWindowScene?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        self.windowScene = windowScene
        startAppCoordinator()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataReset),
            name: .dataDidReset,
            object: nil
        )
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        cleanupTimerOnAppTermination()

        NotificationCenter.default.removeObserver(self)
        appCoordinator?.finish()
        appCoordinator = nil
        windowScene = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleDeepLink(url)
    }
    
    private func startAppCoordinator() {
        guard let windowScene = windowScene else { return }

        appCoordinator?.finish()
        appCoordinator = nil

        appCoordinator = AppCoordinator(windowScene: windowScene)
        appCoordinator?.start()
    }

    @objc private func handleDataReset() {
        DispatchQueue.main.async { [weak self] in
            self?.startAppCoordinator()
        }
    }

    private func handleDeepLink(_ url: URL) {

        guard url.scheme == "cerchio" else {
            return
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 1 else {
            return
        }

        let action = pathComponents[0]

        switch action {
        case "timer":
            fallthrough
        default:
            break
        }
    }

    private func cleanupTimerOnAppTermination() {
        if #available(iOS 16.2, *) {
            _ = LiveActivityManager.shared.endActivity()
                .subscribe(onNext: {
                    
                }, onError: { error in
                    print("[SceneDelegate]  Failed to end Live Activity: \(error)")
                })
        }

        NotificationManager.shared.cancelTimerCompletionNotification()
    }
}

extension Notification.Name {
    static let dataDidReset = Notification.Name("com.cerchio.dataDidReset")
}
