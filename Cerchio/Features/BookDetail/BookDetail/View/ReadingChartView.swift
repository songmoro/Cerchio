//
//  ReadingChartView.swift
//  Cerchio
//
//  Created by 송재훈 on 10/18/25.
//

import SwiftUI
import Charts

struct ReadingChartView: View {
    let chartData: ReadingChartData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartData.isEmpty {
                emptyStateView
            } else {
                headerView
                chartView
            }
        }
        .padding(16)
        .background(Color(uiColor: UIColor(named: "BookBackground")?.withAlphaComponent(0.1) ?? .systemGray6))
        .cornerRadius(12)
    }

    private var emptyStateView: some View {
        Text("아직 독서 기록이 없습니다")
            .font(.system(size: 15))
            .foregroundColor(Color(uiColor: UIColor(named: "ForestGreen")?.withAlphaComponent(0.6) ?? .gray))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
    }

    private var headerView: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(chartData.totalMinutes)분")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))

                Text("\(chartData.sessionCount)회 독서")
                    .font(.system(size: 14))
                    .foregroundColor(Color(uiColor: UIColor(named: "ForestGreen")?.withAlphaComponent(0.7) ?? .gray))
            }

            Spacer()

            Text(chartData.dateRange)
                .font(.system(size: 14))
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }

    @ViewBuilder
    private var chartView: some View {
        if chartData.period == .total || chartData.period == .today {
            hourlyChart
        } else if chartData.period == .week {
            weeklyChart
        } else {
            monthlyChart
        }
    }

    private var hourlyChart: some View {
        Chart(chartData.dataPoints) { dataPoint in
            BarMark(
                x: .value("시간", dataPoint.xValue.isEmpty ? String(dataPoint.id) : dataPoint.xValue),
                yStart: .value("시작", dataPoint.startMinute),
                yEnd: .value("종료", dataPoint.endMinute)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let stringValue = value.as(String.self), !stringValue.isEmpty {
                    AxisValueLabel(stringValue)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 20, 40, 60]) { value in
                AxisGridLine()
                AxisValueLabel("\(value.as(Int.self) ?? 0)")
            }
        }
        .chartYScale(domain: 0...60)
        .frame(height: 140)
    }

    private var weeklyChart: some View {
        Chart(chartData.dataPoints) { dataPoint in
            BarMark(
                x: .value("요일", dataPoint.xValue),
                y: .value("분", dataPoint.durationMinutes)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 140)
    }

    private var monthlyChart: some View {
        Chart(chartData.dataPoints) { dataPoint in
            BarMark(
                x: .value("일", dataPoint.xValue),
                y: .value("분", dataPoint.durationMinutes)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 140)
    }
}

#Preview {
    let sampleData = ReadingChartData(
        period: .today,
        dataPoints: [
            ReadingChartData.DataPoint(id: "12", xValue: "12 PM", startMinute: 20, endMinute: 40),
            ReadingChartData.DataPoint(id: "14", xValue: "", startMinute: 40, endMinute: 50)
        ],
        totalMinutes: 30,
        sessionCount: 2,
        dateRange: "2025년 10월 18일"
    )

    return ReadingChartView(chartData: sampleData)
        .previewLayout(.sizeThatFits)
        .padding()
}
