//
//  TimerBackgroundUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerBackgroundUseCase {

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
    ) -> Observable<Void> {

        guard let targetEndTime = stateManager.currentTargetEndTime else {
            return .error(NSError(domain: "TimerBackgroundUseCase", code: -1))
        }

        sessionManager.saveActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: sessionStartTime,
            targetEndTime: targetEndTime,
            pausedAt: stateManager.currentPausedAt,
            activityId: nil
        )

        return .just(())
    }
}
