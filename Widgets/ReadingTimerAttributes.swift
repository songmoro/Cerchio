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
        var timerStartTime: Date?  // 타이머가 실행 중일 때의 기준 시간
        var pausedElapsedSeconds: Int  // 일시정지 시 경과 시간
        var targetSeconds: Int
        var isPaused: Bool
        var isCompleted: Bool

        // 현재 경과 시간 계산 (위젯에서 실시간으로 계산)
        var currentElapsedSeconds: Int {
            if isCompleted {
                return targetSeconds
            }

            if isPaused {
                return pausedElapsedSeconds
            }

            guard let startTime = timerStartTime else {
                return pausedElapsedSeconds
            }

            let elapsed = Int(Date().timeIntervalSince(startTime))
            let total = pausedElapsedSeconds + elapsed
            return min(total, targetSeconds)
        }

        var currentRemainingSeconds: Int {
            return max(0, targetSeconds - currentElapsedSeconds)
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
