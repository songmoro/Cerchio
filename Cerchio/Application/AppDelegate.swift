//
//  AppDelegate.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit
import RealmSwift
import UserNotifications
import RxSwift
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        configureRealm()
        setupNotifications()
        updateBadgeCount()
        cleanupExpiredNotifications()
        return true
    }

    private func configureRealm() {
        // Schema version: (major * 1000) + (minor * 100) + build
        // v1.2 build 2 = 1000 + 200 + 2 = 1202
        let schemaVersion: UInt64 = 1201

        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // Migration from version < 1202 (v1.2 build 1)
                if oldSchemaVersion < 1201 {
                    // Added custom book info properties
                    migration.enumerateObjects(ofType: "RealmBook") { oldObject, newObject in
                        // Set default nil for new optional properties
                        newObject!["customTitle"] = nil
                        newObject!["customAuthor"] = nil
                        newObject!["customCoverImagePath"] = nil
                    }
                }
            }
        )

        Realm.Configuration.defaultConfiguration = config

        #if DEBUG
        do {
            let realm = try Realm()
            print("📦 Realm configured successfully")
            print("📍 Realm file URL: \(realm.configuration.fileURL?.absoluteString ?? "N/A")")
            print("📊 Schema version: \(schemaVersion)")
        } catch {
            print("❌ Realm configuration failed: \(error)")
        }
        #endif
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }

    private func updateBadgeCount() {
        NotificationManager.shared.updateBadgeCount()
            .subscribe(onNext: { count in
                print("[AppDelegate] 📛 Initial badge count: \(count)")
            })
            .disposed(by: disposeBag)
    }

    private func cleanupExpiredNotifications() {
        NotificationManager.shared.cleanupExpiredNotifications()
            .subscribe(onNext: {
                print("[AppDelegate] 🧹 Expired notifications cleaned")
            })
            .disposed(by: disposeBag)
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    // 포그라운드에서 알림 수신 시
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("[AppDelegate] 📬 Notification will present: \(notification.request.identifier)")

        // 알림을 전달됨으로 표시
        if let notificationId = notification.request.content.userInfo["notificationId"] as? String {
            NotificationManager.shared.markAsDelivered(notificationId: notificationId)
                .subscribe()
                .disposed(by: disposeBag)
        }

        // 알림 표시 (배너, 소리, 배지)
        completionHandler([.banner, .sound, .badge])
    }

    // 사용자가 알림을 탭했을 때
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("[AppDelegate] 👆 Notification tapped: \(response.notification.request.identifier)")

        // 알림을 읽음으로 표시
        if let notificationId = response.notification.request.content.userInfo["notificationId"] as? String {
            NotificationManager.shared.markAsDismissed(notificationId: notificationId)
                .subscribe(onNext: {
                    print("[AppDelegate] ✅ Notification marked as dismissed")
                })
                .disposed(by: disposeBag)
        }

        // TODO: 알림 타입에 따라 적절한 화면으로 이동
        // 예: 타이머 완료 알림이면 해당 세션으로 이동

        completionHandler()
    }
}
