//
//  TimerBackgroundUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 유즈케이스: 백그라운드 진입
/// 1. 현재 세션 상태 저장 (앱 종료 대비)
/// 2. 정확한 경과 시간과 상태 기록
final class TimerBackgroundUseCase {

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
    ) -> Observable<Void> {
        print("[TimerBackgroundUseCase]  Entering background")
        print("  - state: \(stateManager.currentState)")
        print("  - targetEndTime: \(String(describing: stateManager.currentTargetEndTime))")
        print("  - pausedAt: \(String(describing: stateManager.currentPausedAt))")

        // 백그라운드 진입 시 즉시 저장하여 오차 최소화
        guard let targetEndTime = stateManager.currentTargetEndTime else {
            print("[TimerBackgroundUseCase]  No targetEndTime")
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

        print("[TimerBackgroundUseCase]  Session saved")
        return .just(())
    }
}
