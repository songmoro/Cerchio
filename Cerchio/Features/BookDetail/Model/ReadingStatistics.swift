//
//  ReadingStatistics.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation

// MARK: - Reading Statistics

nonisolated struct ReadingStatistics: Hashable {
    let totalTime: Int // 초 단위
    let totalSessions: Int
    let todayTime: Int
    let todaySessions: Int
    let weekTime: Int
    let weekSessions: Int
    let monthTime: Int
    let monthSessions: Int

    var isEmpty: Bool {
        totalSessions == 0
    }

    // 전체 시간 포맷 (시간:분)
    var totalTimeFormatted: String {
        formatTime(totalTime)
    }

    // 오늘 시간 포맷
    var todayTimeFormatted: String {
        formatTime(todayTime)
    }

    // 이번 주 시간 포맷
    var weekTimeFormatted: String {
        formatTime(weekTime)
    }

    // 이번 달 시간 포맷
    var monthTimeFormatted: String {
        formatTime(monthTime)
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return String(format: "%d시간 %d분", hours, minutes)
        } else {
            return String(format: "%d분", minutes)
        }
    }

    static var empty: ReadingStatistics {
        ReadingStatistics(
            totalTime: 0,
            totalSessions: 0,
            todayTime: 0,
            todaySessions: 0,
            weekTime: 0,
            weekSessions: 0,
            monthTime: 0,
            monthSessions: 0
        )
    }
}

// MARK: - Period Statistics

struct PeriodStatistics: Hashable {
    let period: String
    let time: Int
    let sessionCount: Int

    var timeFormatted: String {
        let hours = time / 3600
        let minutes = (time % 3600) / 60

        if hours > 0 {
            return String(format: "%d시간 %d분", hours, minutes)
        } else {
            return String(format: "%d분", minutes)
        }
    }
}
