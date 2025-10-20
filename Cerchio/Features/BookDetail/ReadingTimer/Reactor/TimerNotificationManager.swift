//
//  TimerNotificationManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 타이머 완료 알림 관리 전담 클래스
final class TimerNotificationManager {

    // MARK: - Properties

    private let notificationManager: NotificationManager
    private var scheduledNotificationId: String?
    private var isScheduled = false

    // MARK: - Initialization

    init(notificationManager: NotificationManager = .shared) {
        self.notificationManager = notificationManager
    }

    // MARK: - Schedule

    /// 타이머 완료 알림 스케줄 (절대 시간)
    func scheduleAt(
        targetEndTime: Date,
        sessionId: String,
        bookTitle: String
    ) -> Observable<String> {
        guard !isScheduled else {
            print("[TimerNotification]  Already scheduled")
            return .empty()
        }

        let afterSeconds = max(0, targetEndTime.timeIntervalSince(Date()))

        return notificationManager.scheduleTimerCompletionNotification(
            afterSeconds: afterSeconds,
            sessionId: sessionId,
            bookTitle: bookTitle
        )
        .do(onNext: { [weak self] notificationId in
            self?.scheduledNotificationId = notificationId
            self?.isScheduled = true
            print("[TimerNotification]  Scheduled at \(targetEndTime) with ID: \(notificationId)")
        })
    }

    /// 알림 취소
    func cancel() -> Observable<Void> {
        guard let notificationId = scheduledNotificationId else {
            // 레거시 호환
            notificationManager.cancelTimerCompletionNotification()
            // 전달된 알림도 제거
            notificationManager.removeDeliveredNotification(withIdentifier: "timer_completion")
            isScheduled = false
            print("[TimerNotification]  Cancelled (legacy)")
            return .just(())
        }

        return notificationManager.cancelNotification(withIdentifier: notificationId)
            .do(onNext: { [weak self] in
                // 전달된 알림도 제거
                self?.notificationManager.removeDeliveredNotification(withIdentifier: notificationId)
                self?.scheduledNotificationId = nil
                self?.isScheduled = false
                print("[TimerNotification]  Cancelled with ID: \(notificationId)")
            })
    }

    /// 재스케줄 (종료 시간 변경 시)
    func reschedule(
        targetEndTime: Date,
        sessionId: String,
        bookTitle: String
    ) -> Observable<Void> {
        return cancel()
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.scheduleAt(
                    targetEndTime: targetEndTime,
                    sessionId: sessionId,
                    bookTitle: bookTitle
                )
                .map { _ in () }
            }
    }

    // MARK: - State

    var currentNotificationId: String? {
        scheduledNotificationId
    }

    var hasScheduledNotification: Bool {
        isScheduled
    }
}
