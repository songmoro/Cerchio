//
//  FCMManager.swift
//  Cerchio
//
//  Created by 송재훈 on 11/2/25.
//

import UIKit
import Foundation
import FirebaseMessaging
import RxSwift
import UserNotifications

final class FCMManager: NSObject {
    static let shared = FCMManager()

    private let disposeBag = DisposeBag()
    private let fcmTokenRelay = BehaviorSubject<String?>(value: nil)

    var fcmToken: Observable<String?> {
        return fcmTokenRelay.asObservable()
    }

    private override init() {
        super.init()
        setupFCM()
    }

    private func setupFCM() {
        Messaging.messaging().delegate = self

        #if DEBUG
        Messaging.messaging().isAutoInitEnabled = true
        print("FCM: Running in DEBUG mode - using sandbox APNS")
        #else
        print("FCM: Running in RELEASE mode - using production APNS")
        #endif
    }

    private func getAPNSEnvironment() -> String {
        #if DEBUG
        return "development"
        #else
        return "production"
        #endif
    }

    func requestPermissionAndGetToken() -> Observable<String?> {
        return Observable.create { [weak self] observer in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("FCM permission error: \(error.localizedDescription)")
                    observer.onNext(nil)
                    observer.onCompleted()
                    return
                }

                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }

                    Messaging.messaging().token { token, error in
                        if let error = error {
                            print("FCM token fetch error: \(error.localizedDescription)")
                            observer.onNext(nil)
                        } else if let token = token {
                            let environment = self?.getAPNSEnvironment() ?? "unknown"
                            print("FCM token (\(environment)): \(token)")
                            self?.fcmTokenRelay.onNext(token)
                            observer.onNext(token)
                        }
                        observer.onCompleted()
                    }
                } else {
                    print("FCM permission denied")
                    observer.onNext(nil)
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    func refreshToken() -> Observable<String?> {
        return Observable.create { [weak self] observer in
            Messaging.messaging().token { token, error in
                if let error = error {
                    print("FCM token refresh error: \(error.localizedDescription)")
                    observer.onNext(nil)
                } else if let token = token {
                    print("FCM token refreshed: \(token)")
                    self?.fcmTokenRelay.onNext(token)
                    observer.onNext(token)
                }
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func deleteToken() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            Messaging.messaging().deleteToken { error in
                if let error = error {
                    print("FCM token delete error: \(error.localizedDescription)")
                    observer.onError(error)
                } else {
                    print("FCM token deleted successfully")
                    self?.fcmTokenRelay.onNext(nil)
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    func subscribe(to topic: String) -> Observable<Void> {
        return Observable.create { observer in
            Messaging.messaging().subscribe(toTopic: topic) { error in
                if let error = error {
                    print("FCM topic subscription error: \(error.localizedDescription)")
                    observer.onError(error)
                } else {
                    print("Subscribed to topic: \(topic)")
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    func unsubscribe(from topic: String) -> Observable<Void> {
        return Observable.create { observer in
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in
                if let error = error {
                    print("FCM topic unsubscription error: \(error.localizedDescription)")
                    observer.onError(error)
                } else {
                    print("Unsubscribed from topic: \(topic)")
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }
}

extension FCMManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let environment = getAPNSEnvironment()
        print("FCM registration token (\(environment)): \(fcmToken ?? "nil")")
        fcmTokenRelay.onNext(fcmToken)

        let dataDict: [String: String] = [
            "token": fcmToken ?? "",
            "environment": environment
        ]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
