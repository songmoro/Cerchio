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
import FirebaseMessaging

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        configureRealm()
        setupNotifications()
        setupFCM()
        updateBadgeCount()
        cleanupExpiredNotifications()
        return true
    }

    private func configureFirebase() {
        #if DEBUG
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info-dev", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("GoogleService-Info-dev.plist not found")
        }
        FirebaseApp.configure(options: options)
        print("Firebase configured with Development settings (com.moro.Cerchio.dev)")
        #else
        guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("GoogleService-Info.plist not found")
        }
        FirebaseApp.configure(options: options)
        print("Firebase configured with Production settings (com.moro.Cerchio)")
        #endif
    }

    private func configureRealm() {
        let schemaVersion: UInt64 = 1201

        let config = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1201 {
                    migration.enumerateObjects(ofType: "RealmBook") { oldObject, newObject in
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
            print("Realm configured successfully")
            print("Realm file URL: \(realm.configuration.fileURL?.absoluteString ?? "N/A")")
            print("Schema version: \(schemaVersion)")
        } catch {
            print("Realm configuration failed: \(error)")
        }
        #endif
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }

    private func setupFCM() {
        FCMManager.shared.requestPermissionAndGetToken()
            .subscribe(onNext: { token in
                if let token = token {
                    print("FCM token received in AppDelegate: \(token)")
                }
            })
            .disposed(by: disposeBag)
    }

    private func updateBadgeCount() {
        NotificationManager.shared.updateBadgeCount()
            .subscribe(onNext: { count in
            })
            .disposed(by: disposeBag)
    }

    private func cleanupExpiredNotifications() {
        NotificationManager.shared.cleanupExpiredNotifications()
            .subscribe(onNext: {
            })
            .disposed(by: disposeBag)
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if DEBUG
        Messaging.messaging().apnsToken = deviceToken
        print("APNS Token registered (sandbox): \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        #else
        Messaging.messaging().apnsToken = deviceToken
        print("APNS Token registered (production): \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        #endif
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if let notificationId = notification.request.content.userInfo["notificationId"] as? String {
            NotificationManager.shared.markAsDelivered(notificationId: notificationId)
                .subscribe()
                .disposed(by: disposeBag)
        }

        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let notificationId = response.notification.request.content.userInfo["notificationId"] as? String {
            NotificationManager.shared.markAsDismissed(notificationId: notificationId)
                .subscribe(onNext: {

                })
                .disposed(by: disposeBag)
        }

        completionHandler()
    }
}
