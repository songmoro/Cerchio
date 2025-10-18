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
    let onPeriodChanged: ((ReadingStatisticsPeriod) -> Void)?
    let onSwipe: ((SwipeDirection) -> Void)?

    @State private var selectedPeriod: ReadingStatisticsPeriod

    enum SwipeDirection {
        case left  // 다음 기간
        case right // 이전 기간
    }

    init(chartData: ReadingChartData, onPeriodChanged: ((ReadingStatisticsPeriod) -> Void)? = nil, onSwipe: ((SwipeDirection) -> Void)? = nil) {
        self.chartData = chartData
        self.onPeriodChanged = onPeriodChanged
        self.onSwipe = onSwipe
        _selectedPeriod = State(initialValue: chartData.period)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if chartData.isEmpty {
                emptyStateView
            } else {
                headerView
                chartView
                HStack {
                    Spacer()
                    segmentControl
                    Spacer()
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(uiColor: UIColor(named: "BookBackground")?.withAlphaComponent(0.1) ?? .systemGray6))
        .cornerRadius(12)
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 {
                        // 왼쪽으로 스와이프 = 다음 기간
                        onSwipe?(.left)
                    } else if value.translation.width > 50 {
                        // 오른쪽으로 스와이프 = 이전 기간
                        onSwipe?(.right)
                    }
                }
        )
    }

    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach([ReadingStatisticsPeriod.today, .week, .month, .year], id: \.self) { period in
                Button(action: {
                    selectedPeriod = period
                    onPeriodChanged?(period)
                }) {
                    Text(periodTitle(for: period))
                        .font(.system(size: 14, weight: selectedPeriod == period ? .semibold : .regular))
                        .foregroundColor(selectedPeriod == period ? .white : Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period
                                ? Color(uiColor: UIColor(named: "ForestGreen") ?? .green)
                                : Color.clear
                        )
                }
                .buttonStyle(PlainButtonStyle())

                if period != .year {
                    Divider()
                        .frame(height: 20)
                        .background(Color(uiColor: UIColor(named: "ForestGreen")?.withAlphaComponent(0.3) ?? .gray))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(uiColor: UIColor(named: "ForestGreen") ?? .green), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: 280)
    }

    private func periodTitle(for period: ReadingStatisticsPeriod) -> String {
        switch period {
        case .today: return "오늘"
        case .week: return "이번 주"
        case .month: return "이번 달"
        case .year: return "올해"
        }
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
        if chartData.period == .today {
            hourlyChart
        } else if chartData.period == .week {
            weeklyChart
        } else if chartData.period == .month {
            monthlyChart
        } else {
            yearlyChart
        }
    }

    private var hourlyChart: some View {
        Chart {
            ForEach(0..<24, id: \.self) { hour in
                createHourBar(for: hour)
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18]) { value in
                if let hour = value.as(Int.self) {
                    AxisValueLabel(formatHourLabel(hour))
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

    @ChartContentBuilder
    private func createHourBar(for hour: Int) -> some ChartContent {
        if let dataPoint = chartData.dataPoints.first(where: { Int($0.id) == hour }) {
            BarMark(
                x: .value("시간", hour),
                yStart: .value("시작", dataPoint.startMinute),
                yEnd: .value("종료", dataPoint.endMinute)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        } else {
            BarMark(
                x: .value("시간", hour),
                y: .value("값", 0)
            )
            .foregroundStyle(Color.clear)
        }
    }

    private func formatHourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12 AM"
        case 6: return "6"
        case 12: return "12 PM"
        case 18: return "6"
        default: return ""
        }
    }

    private var weeklyChart: some View {
        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

        return Chart {
            ForEach(1...7, id: \.self) { weekday in
                createWeekdayBar(for: weekday, label: weekdaySymbols[weekday - 1])
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 140)
    }

    @ChartContentBuilder
    private func createWeekdayBar(for weekday: Int, label: String) -> some ChartContent {
        if let dataPoint = chartData.dataPoints.first(where: { Int($0.id) == weekday }) {
            BarMark(
                x: .value("요일", label),
                y: .value("분", dataPoint.durationMinutes)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        } else {
            BarMark(
                x: .value("요일", label),
                y: .value("분", 0)
            )
            .foregroundStyle(Color.clear)
        }
    }

    private var monthlyChart: some View {
        let daysInMonth = getDaysInCurrentMonth()
        let labelDays = stride(from: 1, through: daysInMonth, by: 5).map { $0 }

        return Chart {
            ForEach(1...daysInMonth, id: \.self) { day in
                createDayBar(for: day)
            }
        }
        .chartXAxis {
            AxisMarks(values: labelDays) { value in
                if let day = value.as(Int.self) {
                    AxisValueLabel(String(day))
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 140)
    }

    @ChartContentBuilder
    private func createDayBar(for day: Int) -> some ChartContent {
        if let dataPoint = chartData.dataPoints.first(where: { Int($0.id) == day }) {
            BarMark(
                x: .value("일", day),
                y: .value("분", dataPoint.durationMinutes)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        } else {
            BarMark(
                x: .value("일", day),
                y: .value("분", 0)
            )
            .foregroundStyle(Color.clear)
        }
    }

    private func getDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)
        return range?.count ?? 30
    }

    private var yearlyChart: some View {
        let monthSymbols = ["1월", "2월", "3월", "4월", "5월", "6월", "7월", "8월", "9월", "10월", "11월", "12월"]

        return Chart {
            ForEach(1...12, id: \.self) { month in
                createMonthBar(for: month, label: monthSymbols[month - 1])
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 140)
    }

    @ChartContentBuilder
    private func createMonthBar(for month: Int, label: String) -> some ChartContent {
        if let dataPoint = chartData.dataPoints.first(where: { Int($0.id) == month }) {
            BarMark(
                x: .value("월", label),
                y: .value("분", dataPoint.durationMinutes)
            )
            .foregroundStyle(Color(uiColor: UIColor(named: "ForestGreen") ?? .green))
            .cornerRadius(4)
        } else {
            BarMark(
                x: .value("월", label),
                y: .value("분", 0)
            )
            .foregroundStyle(Color.clear)
        }
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
