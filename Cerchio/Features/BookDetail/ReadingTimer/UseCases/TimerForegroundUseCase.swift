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
                return activityManager.end()
                    .observe(on: MainScheduler.asyncInstance)
                    .map { .completed }
                    .catch { _ in .just(.completed) }
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
            let cancelNotification = notificationManager.cancel()
                .observe(on: MainScheduler.asyncInstance)
                .catch { _ in .just(()) }

            let endActivity: Observable<Void>
            if #available(iOS 16.2, *) {
                endActivity = activityManager.end()
                    .observe(on: MainScheduler.asyncInstance)
                    .catch { _ in .just(()) }
            } else {
                endActivity = .just(())
            }

            return Observable.zip(cancelNotification, endActivity)
                .observe(on: MainScheduler.asyncInstance)
                .do(onNext: { [weak self] _ in
                    self?.sessionManager.clearActiveSession()
                })
                .map { _ in .completed }
        }

        let restartActivity: Observable<Void>
        if #available(iOS 16.2, *), !activityManager.hasActiveActivity {
            restartActivity = activityManager.restart(
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionStartTime: sessionStartTime,
                targetEndTime: targetEndTime,
                pausedAt: stateManager.currentPausedAt,
                targetSeconds: stateManager.targetSeconds
            )
            .observe(on: MainScheduler.asyncInstance)
            .catch { _ in .just(()) }
        } else {
            restartActivity = .just(())
        }

        let updateActivity: Observable<Void>
        if #available(iOS 16.2, *) {
            updateActivity = activityManager.update(
                targetEndTime: targetEndTime,
                pausedAt: stateManager.currentPausedAt,
                targetSeconds: stateManager.targetSeconds
            )
            .observe(on: MainScheduler.asyncInstance)
            .catch { _ in .just(()) }
        } else {
            updateActivity = .just(())
        }

        return Observable.zip(restartActivity, updateActivity)
            .observe(on: MainScheduler.asyncInstance)
            .map { [weak self] _ in
                guard let self = self else { return .completed }
                if self.stateManager.currentState == .paused {
                    return .paused(remaining: calc.remaining)
                }
                return .updated(remaining: calc.remaining)
            }
    }
}
