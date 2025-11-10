//
//  WidgetsLiveActivity.swift
//  Widgets
//
//  Created by 송재훈 on 10/3/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Main Widget

@available(iOS 16.2, *)
struct ReadingTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingTimerAttributes.self) { context in
            ReadingTimerLockScreenView(context: context)
                .activityBackgroundTint(Color("BookBackground"))
                .activitySystemActionForegroundColor(Color("ForestGreen"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    DynamicIslandExpandedContentView(context: context)
                }
            } compactLeading: {
                DynamicIslandCompactLeadingView()
            } compactTrailing: {
                DynamicIslandCompactTrailingView(context: context)
            } minimal: {
                DynamicIslandMinimalView()
            }
            .keylineTint(Color("BookBackground"))
        }
    }
}

// MARK: - Common Components

@available(iOS 16.1, *)
struct BookTitleHeaderView: View {
    let title: String
    let logoSize: CGFloat
    let titleFont: Font
    let titleColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image("ClearLogo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)

            Text(title)
                .font(titleFont)
                .foregroundColor(titleColor)
                .lineLimit(1)

            Spacer()
        }
    }
}

@available(iOS 16.1, *)
struct RemainingTimeDisplayView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>
    let font: Font
    let foregroundColor: Color
    let showCompletionEmoji: Bool

    init(
        context: ActivityViewContext<ReadingTimerAttributes>,
        font: Font = .title2,
        foregroundColor: Color = Color("ForestGreen"),
        showCompletionEmoji: Bool = false
    ) {
        self.context = context
        self.font = font
        self.foregroundColor = foregroundColor
        self.showCompletionEmoji = showCompletionEmoji
    }

    var body: some View {
        if isCompleted {
            if showCompletionEmoji {
                Text("🎉")
                    .font(.largeTitle)
            } else {
                Text("완료")
                    .font(font)
                    .fontWeight(.bold)
                    .foregroundColor(foregroundColor)
            }
        } else if let timerStart = context.state.timerStartTime, !context.state.isPaused {
            // 실행 중: 종료 시간까지 카운트다운
            let endDate = timerStart.addingTimeInterval(TimeInterval(context.state.targetSeconds - context.state.pausedElapsedSeconds))
            Text(endDate, style: .timer)
                .multilineTextAlignment(.trailing)
                .font(font)
                .fontWeight(.bold)
                .foregroundColor(foregroundColor)
                .monospacedDigit()
        } else {
            // 일시정지: 정적 텍스트
            Text(timeString(context.state.currentRemainingSeconds))
                .font(font)
                .fontWeight(.bold)
                .foregroundColor(foregroundColor)
                .monospacedDigit()
        }
    }

    private var isCompleted: Bool {
        context.state.isCompleted || context.state.currentElapsedSeconds >= context.state.targetSeconds
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - Dynamic Island Components

@available(iOS 16.1, *)
struct DynamicIslandExpandedContentView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // 도서명
            Text(context.attributes.bookTitle)
                .font(.body)
                .foregroundColor(Color("BookBackground"))
                .lineLimit(1)

            // 남은 시간
            VStack(spacing: 4) {
                if !isCompleted {
                    Text("남은 시간")
                        .font(.caption)
                        .foregroundColor(Color("BookBackground"))
                }

                RemainingTimeDisplayView(
                    context: context,
                    font: .title,
                    foregroundColor: Color("BookBackground"),
                    showCompletionEmoji: true
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var isCompleted: Bool {
        context.state.isCompleted || context.state.currentElapsedSeconds >= context.state.targetSeconds
    }
}

@available(iOS 16.1, *)
struct DynamicIslandCompactLeadingView: View {
    var body: some View {
        Image("InvertedClearLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    }
}

@available(iOS 16.1, *)
struct DynamicIslandCompactTrailingView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>

    var body: some View {
        RemainingTimeDisplayView(
            context: context,
            font: .caption2,
            foregroundColor: Color("BookBackground")
        )
    }
}

@available(iOS 16.1, *)
struct DynamicIslandMinimalView: View {
    var body: some View {
        Image("InvertedClearLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    }
}

// MARK: - Lock Screen

@available(iOS 16.1, *)
struct ReadingTimerLockScreenView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // 로고 + 도서명
            BookTitleHeaderView(
                title: context.attributes.bookTitle,
                logoSize: 32,
                titleFont: .headline,
                titleColor: Color("ForestGreen")
            )

            if isCompleted {
                // 완료 상태
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text("독서 완료!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("ForestGreen"))
                        Text("🎉")
                            .font(.largeTitle)
                    }
                    Spacer()
                }
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text("목표 시간")
                            .font(.caption2)
                            .foregroundColor(Color("ForestGreen"))

                        Text(timeString(context.state.targetSeconds))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("ForestGreen"))
                            .monospacedDigit()
                    }
                    VStack(alignment: .trailing) {
                        Text("남은 시간")
                            .font(.caption2)
                            .foregroundColor(Color("ForestGreen"))

                        RemainingTimeDisplayView(
                            context: context,
                            font: .title2,
                            foregroundColor: Color("ForestGreen")
                        )
                    }
                }
            }
        }
        .padding(16)
    }

    private var isCompleted: Bool {
        context.state.isCompleted || context.state.currentElapsedSeconds >= context.state.targetSeconds
    }

    private func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
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
            isCompleted: false,
            lastUpdateTime: Date()
        )
    }

    fileprivate static var almostComplete: ReadingTimerAttributes.ContentState {
        ReadingTimerAttributes.ContentState(
            timerStartTime: Date(),
            pausedElapsedSeconds: 0,
            targetSeconds: 1500,
            isPaused: false,
            isCompleted: false,
            lastUpdateTime: Date()
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
