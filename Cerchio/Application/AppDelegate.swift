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
