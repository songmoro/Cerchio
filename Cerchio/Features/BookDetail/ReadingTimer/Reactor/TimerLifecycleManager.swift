//
//  TimerLifecycleManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 앱 라이프사이클(Background/Foreground 전환)에 따른 타이머 동기화 관리
final class TimerLifecycleManager {

    // MARK: - Types

    struct TimeCalculation {
        let remaining: Int
        let isCompleted: Bool
    }

    // MARK: - Properties

    private let targetSeconds: Int

    // MARK: - Initialization

    init(targetSeconds: Int) {
        self.targetSeconds = targetSeconds
    }

    // MARK: - Time Calculation

    /// Foreground 진입 시 시간 계산
    func calculateForegroundTime(targetEndTime: Date, pausedAt: Date?) -> TimeCalculation {
        let remaining: Int

        if let pausedTime = pausedAt {
            // 일시정지 상태: 일시정지 시점의 남은 시간
            remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
        } else {
            // 실행 중: 현재 남은 시간
            remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
        }

        let isCompleted = remaining == 0

        return TimeCalculation(
            remaining: remaining,
            isCompleted: isCompleted
        )
    }

    // MARK: - Logging

    func logForegroundCalculation(_ calc: TimeCalculation) {
        print("[TimerLifecycle]  Foreground time calculation:")
        print("  - remaining: \(calc.remaining)s")
        print("  - isCompleted: \(calc.isCompleted)")
    }
}
