//
//  TimerPauseUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerPauseUseCase {

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
        let pauseTime = Date()

        guard let targetEndTime = stateManager.currentTargetEndTime else {
            return .error(NSError(domain: "TimerPauseUseCase", code: -1))
        }

        stateManager.setState(.paused)
        stateManager.setPausedAt(pauseTime)

        let cancelNotification = notificationManager.cancel()
            .observe(on: MainScheduler.asyncInstance)
            .asObservable()
            .catch { _ in .just(()) }

        let updateActivity: Observable<Void>
        if #available(iOS 16.2, *) {
            updateActivity = activityManager.update(
                targetEndTime: targetEndTime,
                pausedAt: pauseTime,
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
            targetEndTime: targetEndTime,
            pausedAt: pauseTime,
            activityId: nil,
            pausedElapsedSeconds: stateManager.currentElapsedSeconds
        )

        return Observable.zip(cancelNotification, updateActivity)
            .observe(on: MainScheduler.asyncInstance)
            .map { _ in () }
    }
}
