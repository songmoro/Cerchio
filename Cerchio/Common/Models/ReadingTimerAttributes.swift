//
//  ReadingTimerAttributes.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import ActivityKit

struct ReadingTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var targetEndTime: Date  // 타이머 종료 시간
        var pausedAt: Date?  // 일시정지 시간 (nil이면 실행 중)
        var targetSeconds: Int
        var isCompleted: Bool

        // 현재 경과 시간 계산 (위젯에서 실시간으로 계산)
        var currentElapsedSeconds: Int {
            if isCompleted {
                return targetSeconds
            }

            if let pausedTime = pausedAt {
                // 일시정지 상태: 일시정지 시점의 경과 시간
                let remaining = max(0, targetEndTime.timeIntervalSince(pausedTime))
                return targetSeconds - Int(remaining)
            }

            // 실행 중: 현재 경과 시간
            let remaining = max(0, targetEndTime.timeIntervalSince(Date()))
            return min(targetSeconds - Int(remaining), targetSeconds)
        }

        var currentRemainingSeconds: Int {
            if isCompleted {
                return 0
            }

            if let pausedTime = pausedAt {
                // 일시정지 상태: 일시정지 시점의 남은 시간
                return max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
            }

            // 실행 중: 현재 남은 시간
            return max(0, Int(targetEndTime.timeIntervalSince(Date())))
        }

        var isPaused: Bool {
            pausedAt != nil && !isCompleted
        }

        var elapsedTimeString: String {
            formatTime(currentElapsedSeconds)
        }

        var remainingTimeString: String {
            formatTime(currentRemainingSeconds)
        }

        var progress: Double {
            return targetSeconds > 0 ? Double(currentElapsedSeconds) / Double(targetSeconds) : 0
        }

        private func formatTime(_ seconds: Int) -> String {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    var bookTitle: String
    var sessionStartTime: Date
}
