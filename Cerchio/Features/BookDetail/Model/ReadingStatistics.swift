//
//  ReadingStatistics.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation

nonisolated struct ReadingStatistics: Hashable {
    let totalTime: Int
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

    var totalTimeFormatted: String {
        formatTime(totalTime)
    }

    var todayTimeFormatted: String {
        formatTime(todayTime)
    }

    var weekTimeFormatted: String {
        formatTime(weekTime)
    }

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
