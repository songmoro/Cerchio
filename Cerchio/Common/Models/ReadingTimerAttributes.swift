//
//  ReadingTimerAttributes.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import ActivityKit

struct ReadingTimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timerStartTime: Date?
        var pausedElapsedSeconds: Int
        var targetSeconds: Int
        var isPaused: Bool
        var isCompleted: Bool
        var lastUpdateTime: Date  // UI 강제 갱신을 위한 타임스탬프

        var currentElapsedSeconds: Int {
            if isCompleted { return targetSeconds }
            if isPaused || timerStartTime == nil { return pausedElapsedSeconds }
            guard let startTime = timerStartTime else { return pausedElapsedSeconds }
            
            let currentElapsed = Int(Date().timeIntervalSince(startTime))
            return min(pausedElapsedSeconds + currentElapsed, targetSeconds)
        }

        var currentRemainingSeconds: Int { return max(0, targetSeconds - currentElapsedSeconds) }
        var elapsedTimeString: String { formatTime(currentElapsedSeconds) }
        var remainingTimeString: String { formatTime(currentRemainingSeconds) }
        var progress: Double { return targetSeconds > 0 ? Double(currentElapsedSeconds) / Double(targetSeconds) : 0 }

        private func formatTime(_ seconds: Int) -> String {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    var bookTitle: String
    var sessionStartTime: Date
}
