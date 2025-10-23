//
//  TimerForegroundUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerForegroundUseCase {

    enum ForegroundResult {
        case completed
        case updated(remaining: Int)
        case paused(remaining: Int)
    }

    private let stateManager: TimerStateManager
    private let lifecycleManager: TimerLifecycleManager
    private let activityManager: TimerActivityManager
    private let notificationManager: TimerNotificationManager
    private let sessionManager: TimerSessionManager

    init(
        stateManager: TimerStateManager,
        lifecycleManager: TimerLifecycleManager,
        activityManager: TimerActivityManager,
        notificationManager: TimerNotificationManager,
        sessionManager: TimerSessionManager
    ) {
        self.stateManager = stateManager
        self.lifecycleManager = lifecycleManager
        self.activityManager = activityManager
        self.notificationManager = notificationManager
        self.sessionManager = sessionManager
    }

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<ForegroundResult> {

        if stateManager.isCompleted() {
            if #available(iOS 16.2, *) {
                _ = activityManager.end().subscribe()
            }
            return .just(.completed)
        }

        guard let targetEndTime = stateManager.currentTargetEndTime else {
            return .just(.completed)
        }

        let calc = lifecycleManager.calculateForegroundTime(
            targetEndTime: targetEndTime,
            pausedAt: stateManager.currentPausedAt
        )

        if calc.isCompleted {
            _ = notificationManager.cancel().subscribe()
            if #available(iOS 16.2, *) {
                _ = activityManager.end().subscribe()
            }
            sessionManager.clearActiveSession()
            return .just(.completed)
        }

        if #available(iOS 16.2, *), !activityManager.hasActiveActivity {
            _ = activityManager.restart(
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionStartTime: sessionStartTime,
                targetEndTime: targetEndTime,
                pausedAt: stateManager.currentPausedAt,
                targetSeconds: stateManager.targetSeconds
            )
            .subscribe()
        }

        if #available(iOS 16.2, *) {
            _ = activityManager.update(
                targetEndTime: targetEndTime,
                pausedAt: stateManager.currentPausedAt,
                targetSeconds: stateManager.targetSeconds
            )
            .subscribe()
        }

        if stateManager.currentState == .paused {
            return .just(.paused(remaining: calc.remaining))
        }

        return .just(.updated(remaining: calc.remaining))
    }
}
