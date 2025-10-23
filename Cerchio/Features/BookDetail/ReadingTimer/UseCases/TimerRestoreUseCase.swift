//
//  TimerRestoreUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerRestoreUseCase {

    struct RestoreResult {
        let remaining: Int
        let shouldAutoResume: Bool
        let isCompleted: Bool
    }

    private let stateManager: TimerStateManager
    private let lifecycleManager: TimerLifecycleManager
    private let activityManager: TimerActivityManager
    private let sessionRepository: ReadingSessionRepositoryProtocol

    init(
        stateManager: TimerStateManager,
        lifecycleManager: TimerLifecycleManager,
        activityManager: TimerActivityManager,
        sessionRepository: ReadingSessionRepositoryProtocol
    ) {
        self.stateManager = stateManager
        self.lifecycleManager = lifecycleManager
        self.activityManager = activityManager
        self.sessionRepository = sessionRepository
    }

    func execute(
        session: TimerSessionManager.ActiveSession,
        sessionStartTime: Date
    ) -> Observable<RestoreResult> {

        let calc = lifecycleManager.calculateForegroundTime(
            targetEndTime: session.targetEndTime,
            pausedAt: session.pausedAt
        )

        let wasRunning = session.state == "running"
        let finalState: TimerStateManager.TimerState

        if calc.isCompleted {
            finalState = .completed
        } else {
            finalState = wasRunning ? .running : .paused
        }

        stateManager.setState(finalState)
        stateManager.setTargetEndTime(session.targetEndTime)
        stateManager.setPausedAt(session.pausedAt)

        let activitySync: Observable<Void>
        if #available(iOS 16.2, *) {
            if calc.isCompleted {
                activitySync = LiveActivityManager.shared.endAllActivities()
            } else {
                activitySync = activityManager.syncOnRestore(
                    targetEndTime: session.targetEndTime,
                    pausedAt: session.pausedAt,
                    targetSeconds: stateManager.targetSeconds,
                    bookTitle: session.bookTitle,
                    targetMinutes: session.targetMinutes,
                    sessionStartTime: sessionStartTime
                )
            }
        } else {
            activitySync = .just(())
        }

        return Observable.zip(
            activitySync,
            sessionRepository.getSessionById(session.sessionId)
                .observe(on: MainScheduler.instance)
        )
        .map { _, realmSession -> RestoreResult in

            let shouldAutoResume = !calc.isCompleted && session.state == "running"

            if shouldAutoResume {
            } else if calc.isCompleted {
            }

            return RestoreResult(
                remaining: calc.remaining,
                shouldAutoResume: shouldAutoResume,
                isCompleted: calc.isCompleted
            )
        }
    }
}
