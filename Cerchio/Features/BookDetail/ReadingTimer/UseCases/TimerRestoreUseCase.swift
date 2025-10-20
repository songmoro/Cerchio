//
//  TimerRestoreUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 유즈케이스: 앱 재시작 시 세션 복원
/// 1. 저장된 세션 정보로 시간 계산
/// 2. 상태 복원
/// 3. Live Activity 동기화
/// 4. 원래 실행 중이었다면 자동 재개
final class TimerRestoreUseCase {

    // MARK: - Types

    struct RestoreResult {
        let remaining: Int
        let shouldAutoResume: Bool
        let isCompleted: Bool
    }

    // MARK: - Properties

    private let stateManager: TimerStateManager
    private let lifecycleManager: TimerLifecycleManager
    private let activityManager: TimerActivityManager
    private let sessionRepository: ReadingSessionRepositoryProtocol

    // MARK: - Initialization

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

    // MARK: - Execute

    func execute(
        session: TimerSessionManager.ActiveSession,
        sessionStartTime: Date
    ) -> Observable<RestoreResult> {
        print("[TimerRestoreUseCase]  Restoring session")
        print("  - sessionId: \(session.sessionId)")
        print("  - targetEndTime: \(session.targetEndTime)")
        print("  - pausedAt: \(String(describing: session.pausedAt))")
        print("  - session.state: \(session.state)")

        // 1. 시간 계산
        let calc = lifecycleManager.calculateForegroundTime(
            targetEndTime: session.targetEndTime,
            pausedAt: session.pausedAt
        )

        print("[TimerRestoreUseCase] Time calculation:")
        print("  - remaining: \(calc.remaining)s")
        print("  - isCompleted: \(calc.isCompleted)")

        // 2. 상태 복원
        let wasRunning = session.state == "running"
        let finalState: TimerStateManager.TimerState

        if calc.isCompleted {
            print("[TimerRestoreUseCase]  Session already completed, restoring with final state")
            finalState = .completed
        } else {
            print("[TimerRestoreUseCase] Was running? \(wasRunning)")
            finalState = wasRunning ? .running : .paused
        }

        stateManager.setState(finalState)
        stateManager.setTargetEndTime(session.targetEndTime)
        stateManager.setPausedAt(session.pausedAt)

        // 4. Live Activity 동기화 또는 종료
        let activitySync: Observable<Void>
        if #available(iOS 16.2, *) {
            if calc.isCompleted {
                // 완료된 세션은 모든 라이브 액티비티 종료
                print("[TimerRestoreUseCase]  Ending all Live Activities (session completed)")
                activitySync = LiveActivityManager.shared.endAllActivities()
            } else {
                // 진행 중인 세션은 동기화
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

        // 5. 기존 세션 로드 (메인 스레드에서 실행)
        return Observable.zip(
            activitySync,
            sessionRepository.getSessionById(session.sessionId)
                .observe(on: MainScheduler.instance)
        )
        .map { _, realmSession -> RestoreResult in
            print("[TimerRestoreUseCase]  Realm session loaded: \(realmSession?.id ?? "nil")")

            // 6. 자동 재개 여부 결정
            let shouldAutoResume = !calc.isCompleted && session.state == "running"

            if shouldAutoResume {
                print("[TimerRestoreUseCase]  Will auto-resume (was running)")
            } else if calc.isCompleted {
                print("[TimerRestoreUseCase]  Will not resume (already completed)")
            }

            return RestoreResult(
                remaining: calc.remaining,
                shouldAutoResume: shouldAutoResume,
                isCompleted: calc.isCompleted
            )
        }
    }
}
