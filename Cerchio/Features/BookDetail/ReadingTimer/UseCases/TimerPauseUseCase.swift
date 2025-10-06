//
//  TimerPauseUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 유즈케이스: 타이머 일시정지
/// 1. 타이머 틱 중지
/// 2. 일시정지 시간 기록
/// 3. 알림 취소
/// 4. Live Activity 업데이트
/// 5. 세션 저장
final class TimerPauseUseCase {

    // MARK: - Properties

    private let stateManager: TimerStateManager
    private let notificationManager: TimerNotificationManager
    private let activityManager: TimerActivityManager
    private let sessionManager: TimerSessionManager

    // MARK: - Initialization

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

    // MARK: - Execute

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<Void> {
        let pauseTime = Date()

        guard let targetEndTime = stateManager.currentTargetEndTime else {
            print("[TimerPauseUseCase] ❌ No target end time")
            return .error(NSError(domain: "TimerPauseUseCase", code: -1))
        }

        print("[TimerPauseUseCase] ⏸️ Pausing timer")
        print("  - pauseTime: \(pauseTime)")
        print("  - targetEndTime: \(targetEndTime)")

        // 1. 상태 업데이트
        stateManager.setState(.paused)
        stateManager.setPausedAt(pauseTime)

        // 2. 알림 취소
        _ = notificationManager.cancel().subscribe()

        // 3. Live Activity 업데이트
        if #available(iOS 16.2, *) {
            _ = activityManager.update(
                targetEndTime: targetEndTime,
                pausedAt: pauseTime,
                targetSeconds: stateManager.targetSeconds
            )
            .subscribe()
        }

        // 4. 세션 저장
        sessionManager.saveActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: sessionStartTime,
            targetEndTime: targetEndTime,
            pausedAt: pauseTime,
            activityId: nil
        )

        print("[TimerPauseUseCase] ✅ Timer paused successfully")
        return .just(())
    }
}
