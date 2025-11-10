//
//  TimerLifecycleManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerLifecycleManager {

    struct TimeCalculation {
        let remaining: Int
        let isCompleted: Bool
    }

    private let targetSeconds: Int

    init(targetSeconds: Int) {
        self.targetSeconds = targetSeconds
    }

    func calculateForegroundTime(targetEndTime: Date, pausedAt: Date?) -> TimeCalculation {
        let remaining: Int

        if let pausedTime = pausedAt {
            remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
        } else {
            remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
        }

        let isCompleted = remaining == 0

        return TimeCalculation(
            remaining: remaining,
            isCompleted: isCompleted
        )
    }

    func logForegroundCalculation(_ calc: TimeCalculation) {
    }
}
