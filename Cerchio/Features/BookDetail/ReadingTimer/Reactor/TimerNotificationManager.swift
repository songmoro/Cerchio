//
//  TimerNotificationManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerNotificationManager {

    private let notificationManager: NotificationManager
    private var scheduledNotificationId: String?
    private var isScheduled = false

    init(notificationManager: NotificationManager = .shared) {
        self.notificationManager = notificationManager
    }

    func scheduleAt(
        targetEndTime: Date,
        sessionId: String,
        bookTitle: String
    ) -> Observable<String> {
        guard !isScheduled else {
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
        })
    }

    func cancel() -> Observable<Void> {
        guard let notificationId = scheduledNotificationId else {
            notificationManager.cancelTimerCompletionNotification()
            notificationManager.removeDeliveredNotification(withIdentifier: "timer_completion")
            isScheduled = false
            return .just(())
        }

        return notificationManager.cancelNotification(withIdentifier: notificationId)
            .do(onNext: { [weak self] in
                self?.notificationManager.removeDeliveredNotification(withIdentifier: notificationId)
                self?.scheduledNotificationId = nil
                self?.isScheduled = false
            })
    }

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

    var currentNotificationId: String? {
        scheduledNotificationId
    }

    var hasScheduledNotification: Bool {
        isScheduled
    }
}
