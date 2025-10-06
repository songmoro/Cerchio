//
//  TimerForegroundUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 유즈케이스: 포그라운드 복귀
/// 1. 백그라운드에서 경과한 시간 계산
/// 2. 타이머 완료 여부 확인
/// 3. Live Activity 상태 확인 및 복원
/// 4. Smart Delay 적용 (실행 중인 경우)
final class TimerForegroundUseCase {

    // MARK: - Types

    enum ForegroundResult {
        case completed
        case updated(remaining: Int)
        case paused(remaining: Int)
    }

    // MARK: - Properties

    private let stateManager: TimerStateManager
    private let lifecycleManager: TimerLifecycleManager
    private let activityManager: TimerActivityManager
    private let notificationManager: TimerNotificationManager
    private let sessionManager: TimerSessionManager

    // MARK: - Initialization

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

    // MARK: - Execute

    func execute(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<ForegroundResult> {
        print("[TimerForegroundUseCase] 🔄 Returning from background")

        // 1. 타이머가 이미 완료되었으면 Live Activity만 종료
        if stateManager.isCompleted() {
            print("[TimerForegroundUseCase] Timer already completed")
            if #available(iOS 16.2, *) {
                _ = activityManager.end().subscribe()
            }
            return .just(.completed)
        }

        // 2. 시간 계산
        guard let targetEndTime = stateManager.currentTargetEndTime else {
            print("[TimerForegroundUseCase] ❌ No targetEndTime")
            return .just(.completed)
        }

        let calc = lifecycleManager.calculateForegroundTime(
            targetEndTime: targetEndTime,
            pausedAt: stateManager.currentPausedAt
        )

        print("[TimerForegroundUseCase] Time calculation:")
        print("  - remaining: \(calc.remaining)s")
        print("  - isCompleted: \(calc.isCompleted)")

        // 3. 백그라운드에서 완료되었는지 확인
        if calc.isCompleted {
            print("[TimerForegroundUseCase] 🏁 Completed in background")
            _ = notificationManager.cancel().subscribe()
            if #available(iOS 16.2, *) {
                _ = activityManager.end().subscribe()
            }
            sessionManager.clearActiveSession()
            return .just(.completed)
        }

        // 4. Live Activity 복원 (사용자가 닫았을 경우)
        if #available(iOS 16.2, *), !activityManager.hasActiveActivity {
            print("[TimerForegroundUseCase] 📱 Restarting Live Activity")
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

        // 5. Live Activity 업데이트
        if #available(iOS 16.2, *) {
            _ = activityManager.update(
                targetEndTime: targetEndTime,
                pausedAt: stateManager.currentPausedAt,
                targetSeconds: stateManager.targetSeconds
            )
            .subscribe()
        }

        // 6. 일시정지 상태면 시간만 업데이트
        if stateManager.currentState == .paused {
            print("[TimerForegroundUseCase] ⏸️ Paused - updating time only")
            return .just(.paused(remaining: calc.remaining))
        }

        // 7. 실행 중: 시간 업데이트
        print("[TimerForegroundUseCase] ▶️ Running - updating time")
        return .just(.updated(remaining: calc.remaining))
    }
}
