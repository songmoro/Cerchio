//
//  TimerTickUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 유즈케이스: 1초 틱
/// 1. 완료 여부 확인
/// 2. 10초마다 세션 저장 (앱 종료 대비)
final class TimerTickUseCase {

    // MARK: - Properties

    private let stateManager: TimerStateManager
    private let sessionManager: TimerSessionManager

    // MARK: - Initialization

    init(
        stateManager: TimerStateManager,
        sessionManager: TimerSessionManager
    ) {
        self.stateManager = stateManager
        self.sessionManager = sessionManager
    }

    // MARK: - Execute

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<Bool> {
        // 1. 완료 여부 확인
        let isCompleted = stateManager.isTimerCompleted()

        // 2. 10초마다 세션 저장 (종료 시간은 변경되지 않음)
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
