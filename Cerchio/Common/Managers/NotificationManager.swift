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

    private init() {}

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
    func scheduleTimerCompletionNotification(afterSeconds seconds: TimeInterval) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }

            // 알림 내용 설정
            let content = UNMutableNotificationContent()
            content.title = "독서 완료"
            content.body = "목표 시간을 달성했습니다!"
            content.sound = .default
            content.badge = 1

            // 트리거 설정 (시간 기반)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)

            // 요청 생성
            let identifier = "timer_completion"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            // 알림 스케줄
            self.notificationCenter.add(request) { error in
                if let error = error {
                    print("❌ Failed to schedule notification: \(error)")
                } else {
                    print("✅ Notification scheduled for \(seconds) seconds")
                }
                observer.onNext(())
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    /// 특정 식별자의 알림 취소
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("✅ Notification cancelled: \(identifier)")
    }

    /// 타이머 완료 알림 취소
    func cancelTimerCompletionNotification() {
        cancelNotification(withIdentifier: "timer_completion")
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

    /// 앱 배지 제거
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
        print("✅ Badge cleared")
    }
}
