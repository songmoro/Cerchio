//
//  TimerResumeUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerResumeUseCase {

    private let stateManager: TimerStateManager
    private let notificationManager: TimerNotificationManager
    private let activityManager: TimerActivityManager
    private let sessionManager: TimerSessionManager

    init(
        stateManager: TimerStateManager,
        notificationManager: TimerNotificationManager,
        activityManager: TimerActivityManager,
        sessionManager: TimerSessionManager
    ) {
        self.stateManager = stateManager
        self.notificationManager = notificationManager
        self.activityManager = activityManager
        self.sessionManager = sessionManager
    }

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<Void> {
        guard let targetEndTime = stateManager.currentTargetEndTime,
              let pausedAt = stateManager.currentPausedAt else {
            return .error(NSError(domain: "TimerResumeUseCase", code: -1))
        }

        let pauseDuration = Date().timeIntervalSince(pausedAt)
        let newTargetEndTime = targetEndTime.addingTimeInterval(pauseDuration)

        stateManager.setState(.running)
        stateManager.setTargetEndTime(newTargetEndTime)
        stateManager.setPausedAt(nil)

        let rescheduleNotification = notificationManager.reschedule(
            targetEndTime: newTargetEndTime,
            sessionId: sessionId,
            bookTitle: bookTitle
        )
        .observe(on: MainScheduler.asyncInstance)
        .asObservable()
        .catch { _ in .just(()) }

        let updateActivity: Observable<Void>
        if #available(iOS 16.2, *) {
            updateActivity = activityManager.update(
                targetEndTime: newTargetEndTime,
                pausedAt: nil,
                targetSeconds: stateManager.targetSeconds
            )
            .observe(on: MainScheduler.asyncInstance)
        } else {
            updateActivity = .just(())
        }

        sessionManager.saveActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: sessionStartTime,
            targetEndTime: newTargetEndTime,
            pausedAt: nil,
            activityId: nil,
            pausedElapsedSeconds: stateManager.currentElapsedSeconds
        )

        return Observable.zip(rescheduleNotification, updateActivity)
            .observe(on: MainScheduler.asyncInstance)
            .map { _ in () }
    }
}
