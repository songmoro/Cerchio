//
//  NotificationManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import UserNotifications
import RxSwift

final class NotificationManager {

    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let notificationRepository: NotificationRepositoryProtocol
    private let disposeBag = DisposeBag()

    private init() {
        do {
            self.notificationRepository = try NotificationRepository()
        } catch {
            fatalError("Failed to initialize NotificationRepository: \(error)")
        }
    }

    init(notificationRepository: NotificationRepositoryProtocol) {
        self.notificationRepository = notificationRepository
    }

    func requestAuthorization() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }

            self.notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
                if let error = error {
                    print(" Notification authorization error: \(error)")
                    observer.onNext(false)
                } else {
                    observer.onNext(granted)
                }
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func checkAuthorizationStatus() -> Observable<UNAuthorizationStatus> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(.notDetermined)
                observer.onCompleted()
                return Disposables.create()
            }

            self.notificationCenter.getNotificationSettings { settings in
                observer.onNext(settings.authorizationStatus)
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func scheduleTimerCompletionNotification(
        afterSeconds seconds: TimeInterval,
        sessionId: String,
        bookTitle: String
    ) -> Observable<String> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let notificationId = UUID().uuidString
            let scheduledDate = Date().addingTimeInterval(seconds)

            let realmNotification = RealmNotification(
                id: notificationId,
                type: .timerCompletion,
                status: .scheduled,
                scheduledDate: scheduledDate,
                relatedEntityId: sessionId,
                relatedEntityType: .session,
                title: "독서 완료",
                body: "'\(bookTitle)' 목표 시간을 달성했습니다!",
                badge: 1
            )

            self.notificationRepository.saveNotification(realmNotification)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { savedNotification in

                    let content = UNMutableNotificationContent()
                    content.title = savedNotification.title
                    content.body = savedNotification.body
                    content.sound = .default
                    content.userInfo = ["notificationId": savedNotification.id]

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

                    self.notificationCenter.add(request) { error in
                        if let error = error {
                            print("[NotificationManager]  Failed to schedule notification: \(error)")
                        } else {
                        }
                        observer.onNext(notificationId)
                        observer.onCompleted()
                    }
                }, onError: { error in
                    print("[NotificationManager]  Failed to save notification: \(error)")
                    observer.onError(error)
                })
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    func cancelNotification(withIdentifier identifier: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

            self.notificationRepository.cancelNotification(identifier)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: {
                    observer.onNext(())
                    observer.onCompleted()
                }, onError: { error in
                    print("[NotificationManager]  Failed to update notification status: \(error)")
                    observer.onNext(())
                    observer.onCompleted()
                })
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    func cancelTimerCompletionNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["timer_completion"])
    }

    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
    }

    func removeDeliveredNotification(withIdentifier identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    func updateBadgeCount() -> Observable<Int> {
        return notificationRepository.getUnreadCount()
            .observe(on: MainScheduler.instance)
            .do(onNext: { count in
                UNUserNotificationCenter.current().setBadgeCount(count)
            })
    }

    func markAsDelivered(notificationId: String) -> Observable<Void> {
        return notificationRepository.markAsDelivered(notificationId)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .just(()) }
                return self.updateBadgeCount().map { _ in () }
            }
    }

    func markAsDismissed(notificationId: String) -> Observable<Void> {
        return notificationRepository.markAsDismissed(notificationId)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .just(()) }
                return self.updateBadgeCount().map { _ in () }
            }
    }

    func cleanupExpiredNotifications() -> Observable<Void> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return notificationRepository.deleteExpiredNotifications(olderThan: thirtyDaysAgo)
            .observe(on: MainScheduler.instance)
            .do(onNext: {
            })
    }

    func removeInactiveTimerNotifications(activeSessionId: String? = nil) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            self.notificationCenter.getPendingNotificationRequests { requests in
                let timerNotifications = requests.filter { request in
                    request.content.userInfo["type"] as? String == "timerCompletion"
                }

                let notificationsToRemove: [String]
                if let activeId = activeSessionId {
                    notificationsToRemove = timerNotifications
                        .filter { request in
                            let sessionId = request.content.userInfo["sessionId"] as? String
                            return sessionId != activeId
                        }
                        .map { $0.identifier }
                } else {
                    notificationsToRemove = timerNotifications.map { $0.identifier }
                }

                guard !notificationsToRemove.isEmpty else {
                    observer.onNext(())
                    observer.onCompleted()
                    return
                }

                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationsToRemove)

                let cancelObservables = notificationsToRemove.map { identifier in
                    self.notificationRepository.cancelNotification(identifier)
                }

                Observable.zip(cancelObservables)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        observer.onNext(())
                        observer.onCompleted()
                    }, onError: { error in
                        print("[NotificationManager]  Failed to update notification status: \(error)")
                        observer.onNext(())
                        observer.onCompleted()
                    })
                    .disposed(by: self.disposeBag)
            }

            return Disposables.create()
        }
    }
}
