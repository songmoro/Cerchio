//
//  WidgetsLiveActivity.swift
//  Widgets
//
//  Created by 송재훈 on 10/3/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import Combine

@available(iOS 16.2, *)
struct ReadingTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingTimerAttributes.self) { context in
            // Lock screen/banner UI
            ReadingTimerLockScreenView(context: context)
                .activityBackgroundTint(Color(hex: "#F5F1E8"))
                .activitySystemActionForegroundColor(Color(hex: "#2C5F2D"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandTimerView(context: context, showLabel: true, alignment: .leading)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandRemainingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.attributes.bookTitle)
                            .font(.body)
                            .lineLimit(1)
                        ProgressView(value: context.state.progress)
                            .tint(Color(hex: "#2C5F2D"))
                    }
                }
            } compactLeading: {
                Image(systemName: "book.fill")
                    .foregroundColor(Color(hex: "#2C5F2D"))
            } compactTrailing: {
                DynamicIslandTimerView(context: context, showLabel: false, alignment: .trailing)
            } minimal: {
                Image(systemName: "book.fill")
                    .foregroundColor(Color(hex: "#2C5F2D"))
            }
            .keylineTint(Color(hex: "#2C5F2D"))
        }
    }
}

// MARK: - Dynamic Island Timer Views

@available(iOS 16.1, *)
struct DynamicIslandTimerView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>
    let showLabel: Bool
    let alignment: HorizontalAlignment

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            if showLabel {
                Text("경과")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                // 실행 중: Text의 timer 스타일 사용
                Text(timerStart, style: .timer)
                    .font(showLabel ? .title3 : .caption2)
                    .fontWeight(showLabel ? .bold : .medium)
                    .foregroundColor(Color(hex: "#2C5F2D"))
                    .monospacedDigit()
            } else {
                // 일시정지: 정적 텍스트
                Text(timeString(context.state.pausedElapsedSeconds))
                    .font(showLabel ? .title3 : .caption2)
                    .fontWeight(showLabel ? .bold : .medium)
                    .foregroundColor(Color(hex: "#2C5F2D"))
                    .monospacedDigit()
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

@available(iOS 16.1, *)
struct DynamicIslandRemainingView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("남은 시간")
                .font(.caption2)
                .foregroundColor(.secondary)

            if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                // 실행 중: 종료 시간까지 카운트다운
                let endDate = timerStart.addingTimeInterval(TimeInterval(context.state.targetSeconds - context.state.pausedElapsedSeconds))
                Text(endDate, style: .timer)
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
            } else {
                // 일시정지: 정적 텍스트
                Text(timeString(context.state.currentRemainingSeconds))
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

@available(iOS 16.1, *)
struct ReadingTimerLockScreenView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Color(hex: "#2C5F2D"))
                Text(context.attributes.bookTitle)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("경과 시간")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                        Text(timerStart, style: .timer)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#2C5F2D"))
                            .monospacedDigit()
                    } else {
                        Text(timeString(context.state.pausedElapsedSeconds))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#2C5F2D"))
                            .monospacedDigit()
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("남은 시간")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                        let endDate = timerStart.addingTimeInterval(TimeInterval(context.state.targetSeconds - context.state.pausedElapsedSeconds))
                        Text(endDate, style: .timer)
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    } else {
                        Text(timeString(context.state.currentRemainingSeconds))
                            .font(.title2)
                            .fontWeight(.bold)
                            .monospacedDigit()
                    }
                }
            }

            ProgressView(value: context.state.progress)
                .tint(Color(hex: "#2C5F2D"))
        }
        .padding(16)
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

extension ReadingTimerAttributes {
    fileprivate static var preview: ReadingTimerAttributes {
        ReadingTimerAttributes(bookTitle: "해리 포터와 마법사의 돌", sessionStartTime: Date())
    }
}

extension ReadingTimerAttributes.ContentState {
    fileprivate static var running: ReadingTimerAttributes.ContentState {
        ReadingTimerAttributes.ContentState(
            timerStartTime: Date(),
            pausedElapsedSeconds: 0,
            targetSeconds: 1500,
            isPaused: false,
            isCompleted: false
        )
    }

    fileprivate static var almostComplete: ReadingTimerAttributes.ContentState {
        ReadingTimerAttributes.ContentState(
            timerStartTime: Date().addingTimeInterval(-1440),
            pausedElapsedSeconds: 0,
            targetSeconds: 1500,
            isPaused: false,
            isCompleted: false
        )
    }
}

@available(iOS 17.0, *)
#Preview("Notification", as: .content, using: ReadingTimerAttributes.preview) {
   ReadingTimerLiveActivity()
} contentStates: {
    ReadingTimerAttributes.ContentState.running
    ReadingTimerAttributes.ContentState.almostComplete
}
