//
//  ReadingChartData.swift
//  Cerchio
//
//  Created by 송재훈 on 10/18/25.
//

import Foundation

nonisolated struct ReadingChartData: Hashable, Sendable {
    let period: ReadingStatisticsPeriod
    let dataPoints: [DataPoint]
    let totalMinutes: Int
    let sessionCount: Int
    let dateRange: String

    nonisolated struct DataPoint: Hashable, Sendable, Identifiable {
        let id: String
        let xValue: String
        let startMinute: Int
        let endMinute: Int
        let durationMinutes: Int

        init(id: String, xValue: String, startMinute: Int, endMinute: Int) {
            self.id = id
            self.xValue = xValue
            self.startMinute = startMinute
            self.endMinute = endMinute
            self.durationMinutes = endMinute - startMinute
        }
    }

    var isEmpty: Bool {
        dataPoints.isEmpty || totalMinutes == 0
    }
}
