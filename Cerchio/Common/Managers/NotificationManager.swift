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
        // NotificationRepository 초기화 시도, 실패하면 fatal error
        do {
            self.notificationRepository = try NotificationRepository()
        } catch {
            fatalError("Failed to initialize NotificationRepository: \(error)")
        }
    }

    init(notificationRepository: NotificationRepositoryProtocol) {
        self.notificationRepository = notificationRepository
    }

    // MARK: - Authorization

    /// 알림 권한 요청
    func requestAuthorization() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(false)
                observer.onCompleted()
                return Disposables.create()
            }

            self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    print("❌ Notification authorization error: \(error)")
                    observer.onNext(false)
                } else {
                    print("✅ Notification authorization: \(granted)")
                    observer.onNext(granted)
                }
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    /// 현재 알림 권한 상태 확인
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

    // MARK: - Scheduling

    /// 타이머 완료 알림 스케줄
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

            // Realm에 알림 저장 (메인 스레드에서)
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
                    print("[NotificationManager] 💾 Saved notification to Realm: \(savedNotification.id)")

                    // 시스템 알림 스케줄
                    let content = UNMutableNotificationContent()
                    content.title = savedNotification.title
                    content.body = savedNotification.body
                    content.sound = .default
                    content.badge = NSNumber(value: savedNotification.badge)
                    content.userInfo = ["notificationId": savedNotification.id]

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
                    let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

                    self.notificationCenter.add(request) { error in
                        if let error = error {
                            print("[NotificationManager] ❌ Failed to schedule notification: \(error)")
                        } else {
                            print("[NotificationManager] ✅ Notification scheduled for \(seconds) seconds")
                        }
                        observer.onNext(notificationId)
                        observer.onCompleted()
                    }
                }, onError: { error in
                    print("[NotificationManager] ❌ Failed to save notification: \(error)")
                    observer.onError(error)
                })
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    /// 특정 식별자의 알림 취소
    func cancelNotification(withIdentifier identifier: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            // 시스템 알림 취소
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

            // Realm에서 상태 업데이트 (메인 스레드에서)
            self.notificationRepository.cancelNotification(identifier)
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: {
                    print("[NotificationManager] ✅ Notification cancelled: \(identifier)")
                    observer.onNext(())
                    observer.onCompleted()
                }, onError: { error in
                    print("[NotificationManager] ⚠️ Failed to update notification status: \(error)")
                    // 시스템 알림은 이미 취소되었으므로 성공으로 처리
                    observer.onNext(())
                    observer.onCompleted()
                })
                .disposed(by: self.disposeBag)

            return Disposables.create()
        }
    }

    /// 타이머 완료 알림 취소 (레거시 호환)
    func cancelTimerCompletionNotification() {
        // 기존 호환성을 위한 동기 메서드
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["timer_completion"])
        print("[NotificationManager] ✅ Legacy timer notification cancelled")
    }

    /// 모든 예약된 알림 취소
    func cancelAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("✅ All pending notifications cancelled")
    }

    /// 모든 전달된 알림 제거
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        print("✅ All delivered notifications removed")
    }

    /// 특정 전달된 알림 제거
    func removeDeliveredNotification(withIdentifier identifier: String) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
        print("✅ Delivered notification removed: \(identifier)")
    }

    /// 앱 배지 제거
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
        print("✅ Badge cleared")
    }

    // MARK: - Badge Management

    /// 배지 카운트 업데이트
    func updateBadgeCount() -> Observable<Int> {
        return notificationRepository.getUnreadCount()
            .observe(on: MainScheduler.instance)
            .do(onNext: { count in
                UNUserNotificationCenter.current().setBadgeCount(count)
                print("[NotificationManager] 📛 Badge count updated: \(count)")
            })
    }

    /// 알림을 전달됨으로 표시
    func markAsDelivered(notificationId: String) -> Observable<Void> {
        return notificationRepository.markAsDelivered(notificationId)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .just(()) }
                return self.updateBadgeCount().map { _ in () }
            }
    }

    /// 알림을 읽음으로 표시
    func markAsDismissed(notificationId: String) -> Observable<Void> {
        return notificationRepository.markAsDismissed(notificationId)
            .observe(on: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .just(()) }
                return self.updateBadgeCount().map { _ in () }
            }
    }

    /// 만료된 알림 정리 (30일 이상 된 dismissed/cancelled 알림)
    func cleanupExpiredNotifications() -> Observable<Void> {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return notificationRepository.deleteExpiredNotifications(olderThan: thirtyDaysAgo)
            .observe(on: MainScheduler.instance)
            .do(onNext: {
                print("[NotificationManager] 🧹 Expired notifications cleaned up")
            })
    }

    /// 진행 중이 아닌 타이머 알림 제거
    /// - activeSessionId가 있으면 해당 세션 외 모든 타이머 알림 제거
    /// - activeSessionId가 없으면 모든 타이머 알림 제거
    func removeInactiveTimerNotifications(activeSessionId: String? = nil) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            // 1. 시스템의 예약된 알림 확인
            self.notificationCenter.getPendingNotificationRequests { requests in
                let timerNotifications = requests.filter { request in
                    request.content.userInfo["type"] as? String == "timerCompletion"
                }

                // 2. 제거할 알림 식별자 수집
                let notificationsToRemove: [String]
                if let activeId = activeSessionId {
                    // 활성 세션이 있으면 해당 세션 외 모든 타이머 알림 제거
                    notificationsToRemove = timerNotifications
                        .filter { request in
                            let sessionId = request.content.userInfo["sessionId"] as? String
                            return sessionId != activeId
                        }
                        .map { $0.identifier }
                } else {
                    // 활성 세션이 없으면 모든 타이머 알림 제거
                    notificationsToRemove = timerNotifications.map { $0.identifier }
                }

                guard !notificationsToRemove.isEmpty else {
                    print("[NotificationManager] ✅ No inactive timer notifications to remove")
                    observer.onNext(())
                    observer.onCompleted()
                    return
                }

                print("[NotificationManager] 🧹 Removing \(notificationsToRemove.count) inactive timer notification(s)")

                // 3. 시스템 알림 제거
                self.notificationCenter.removePendingNotificationRequests(withIdentifiers: notificationsToRemove)

                // 4. Realm에서 상태 업데이트
                let cancelObservables = notificationsToRemove.map { identifier in
                    self.notificationRepository.cancelNotification(identifier)
                }

                Observable.zip(cancelObservables)
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        print("[NotificationManager] ✅ Inactive timer notifications removed")
                        observer.onNext(())
                        observer.onCompleted()
                    }, onError: { error in
                        print("[NotificationManager] ⚠️ Failed to update notification status: \(error)")
                        // 시스템 알림은 이미 제거되었으므로 성공으로 처리
                        observer.onNext(())
                        observer.onCompleted()
                    })
                    .disposed(by: self.disposeBag)
            }

            return Disposables.create()
        }
    }
}
