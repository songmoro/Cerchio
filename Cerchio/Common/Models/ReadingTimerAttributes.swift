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
        var timerStartTime: Date?  // 타이머 시작 시간 (nil이면 일시정지)
        var pausedElapsedSeconds: Int  // 일시정지 시점의 경과 시간
        var targetSeconds: Int
        var isPaused: Bool
        var isCompleted: Bool

        // 현재 경과 시간 계산 (위젯에서 실시간으로 계산)
        var currentElapsedSeconds: Int {
            if isCompleted {
                return targetSeconds
            }

            if isPaused || timerStartTime == nil {
                // 일시정지 상태
                return pausedElapsedSeconds
            }

            // 실행 중: 시작 시간부터 경과 시간 + 이전 일시정지 누적 시간
            guard let startTime = timerStartTime else {
                return pausedElapsedSeconds
            }
            let currentElapsed = Int(Date().timeIntervalSince(startTime))
            return min(pausedElapsedSeconds + currentElapsed, targetSeconds)
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
