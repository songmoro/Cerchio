//
//  TimerTickUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerTickUseCase {

    private let stateManager: TimerStateManager
    private let sessionManager: TimerSessionManager

    init(
        stateManager: TimerStateManager,
        sessionManager: TimerSessionManager
    ) {
        self.stateManager = stateManager
        self.sessionManager = sessionManager
    }

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<Bool> {
        let isCompleted = stateManager.isTimerCompleted()

        if !isCompleted, let targetEndTime = stateManager.currentTargetEndTime {
            let elapsed = stateManager.currentElapsedSeconds
            if elapsed % 10 == 0 {
                sessionManager.saveActiveSession(
                    sessionId: sessionId,
                    bookId: bookId,
                    bookTitle: bookTitle,
                    targetMinutes: targetMinutes,
                    startTime: sessionStartTime,
                    targetEndTime: targetEndTime,
                    pausedAt: nil,
                    activityId: nil
                )
            }
        }

        return .just(isCompleted)
    }
}
