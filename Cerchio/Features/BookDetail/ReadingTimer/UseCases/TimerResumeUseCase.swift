//
//  TimerResumeUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 유즈케이스: 타이머 재개
/// 1. 일시정지 시간 계산하여 종료 시간 연장
/// 2. 타이머 틱 재시작
/// 3. 알림 재스케줄
/// 4. Live Activity 업데이트
/// 5. 세션 저장
final class TimerResumeUseCase {

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
        guard let targetEndTime = stateManager.currentTargetEndTime,
              let pausedAt = stateManager.currentPausedAt else {
            print("[TimerResumeUseCase] ❌ No pause info")
            return .error(NSError(domain: "TimerResumeUseCase", code: -1))
        }

        print("[TimerResumeUseCase] ▶️ Resuming timer")

        // 1. 일시정지 시간 계산하여 종료 시간 연장
        let pauseDuration = Date().timeIntervalSince(pausedAt)
        let newTargetEndTime = targetEndTime.addingTimeInterval(pauseDuration)

        print("  - pauseDuration: \(pauseDuration)s")
        print("  - newTargetEndTime: \(newTargetEndTime)")

        // 2. 상태 업데이트
        stateManager.setState(.running)
        stateManager.setTargetEndTime(newTargetEndTime)
        stateManager.setPausedAt(nil)

        // 3. 알림 재스케줄
        _ = notificationManager.reschedule(
            targetEndTime: newTargetEndTime,
            sessionId: sessionId,
            bookTitle: bookTitle
        )
        .subscribe()

        // 4. Live Activity 업데이트
        if #available(iOS 16.2, *) {
            _ = activityManager.update(
                targetEndTime: newTargetEndTime,
                pausedAt: nil,
                targetSeconds: stateManager.targetSeconds
            )
            .subscribe()
        }

        // 5. 세션 저장
        sessionManager.saveActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: sessionStartTime,
            targetEndTime: newTargetEndTime,
            pausedAt: nil,
            activityId: nil
        )

        print("[TimerResumeUseCase] ✅ Timer resumed successfully")
        return .just(())
    }
}
