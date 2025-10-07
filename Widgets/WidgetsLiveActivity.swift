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
                .activityBackgroundTint(Color("BookBackground"))
                .activitySystemActionForegroundColor(Color("ForestGreen"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DynamicIslandTimerView(context: context, showLabel: true, alignment: .leading, useBookBackground: true)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    DynamicIslandRemainingView(context: context, useBookBackground: true)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        Text(context.attributes.bookTitle)
                            .font(.body)
                            .foregroundColor(Color("BookBackground"))
                            .lineLimit(1)
                        //                        ProgressView(value: context.state.progress)
                        //                            .tint(Color("BookBackground"))
                    }
                }
            } compactLeading: {
                Image(systemName: "book.fill")
                    .foregroundColor(Color("BookBackground"))
            } compactTrailing: {
                DynamicIslandTimerView(context: context, showLabel: false, alignment: .trailing)
            } minimal: {
                Image(systemName: "book.fill")
                    .foregroundColor(Color("BookBackground"))
            }
            .keylineTint(Color("BookBackground"))
        }
    }
}

// MARK: - Dynamic Island Timer Views

@available(iOS 16.1, *)
struct DynamicIslandTimerView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>
    let showLabel: Bool
    let alignment: HorizontalAlignment
    var useBookBackground: Bool = false
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            if showLabel && !isCompleted {
                Text("경과")
                    .font(.caption2)
                    .foregroundColor(useBookBackground ? Color("BookBackground") : Color("ForestGreen"))
            }
            
            if isCompleted {
                // 완료
                Text("완료")
                    .font(showLabel ? .title3 : .caption2)
                    .fontWeight(.bold)
                    .foregroundColor(useBookBackground || !showLabel ? Color("BookBackground") : Color("ForestGreen"))
            } else if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                // 실행 중: Text의 timer 스타일 사용
                Text(timerStart, style: .timer)
                    .font(showLabel ? .title3 : .caption2)
                    .fontWeight(showLabel ? .bold : .medium)
                    .foregroundColor(useBookBackground || !showLabel ? Color("BookBackground") : Color("ForestGreen"))
                    .monospacedDigit()
            } else {
                // 일시정지: 정적 텍스트
                Text(timeString(context.state.pausedElapsedSeconds))
                    .font(showLabel ? .title3 : .caption2)
                    .fontWeight(showLabel ? .bold : .medium)
                    .foregroundColor(useBookBackground || !showLabel ? Color("BookBackground") : Color("ForestGreen"))
                    .monospacedDigit()
            }
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

@available(iOS 16.1, *)
struct DynamicIslandRemainingView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>
    var useBookBackground: Bool = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if !isCompleted {
                Text("남은 시간")
                    .font(.caption2)
                    .foregroundColor(useBookBackground ? Color("BookBackground") : Color("ForestGreen"))
            }
            
            if isCompleted {
                // 완료
                Text("🎉")
                    .font(.title3)
            } else if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                // 실행 중: 종료 시간까지 카운트다운
                let endDate = timerStart.addingTimeInterval(TimeInterval(context.state.targetSeconds - context.state.pausedElapsedSeconds))
                Text(endDate, style: .timer)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(useBookBackground ? Color("BookBackground") : Color("ForestGreen"))
                    .monospacedDigit()
            } else {
                // 일시정지: 정적 텍스트
                Text(timeString(context.state.currentRemainingSeconds))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(useBookBackground ? Color("BookBackground") : Color("ForestGreen"))
                    .monospacedDigit()
            }
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

@available(iOS 16.1, *)
struct ReadingTimerLockScreenView: View {
    let context: ActivityViewContext<ReadingTimerAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Color("ForestGreen"))
                Text(context.attributes.bookTitle)
                    .font(.headline)
                    .foregroundColor(Color("ForestGreen"))
                    .lineLimit(1)
                Spacer()
            }
            
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
                // 진행 중
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("경과 시간")
                            .font(.caption)
                            .foregroundColor(Color("ForestGreen"))
                        
                        if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                            Text(timerStart, style: .timer)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("ForestGreen"))
                                .monospacedDigit()
                        } else {
                            Text(timeString(context.state.pausedElapsedSeconds))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("ForestGreen"))
                                .monospacedDigit()
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("남은 시간")
                            .font(.caption)
                            .foregroundColor(Color("ForestGreen"))
                        
                        if let timerStart = context.state.timerStartTime, !context.state.isPaused {
                            let endDate = timerStart.addingTimeInterval(TimeInterval(context.state.targetSeconds - context.state.pausedElapsedSeconds))
                            Text(endDate, style: .timer)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("ForestGreen"))
                                .monospacedDigit()
                        } else {
                            Text(timeString(context.state.currentRemainingSeconds))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color("ForestGreen"))
                                .monospacedDigit()
                        }
                    }
                }
            }
            
            ProgressView(value: context.state.progress)
                .tint(Color("ForestGreen"))
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
            isCompleted: false
        )
    }
    
    fileprivate static var almostComplete: ReadingTimerAttributes.ContentState {
        ReadingTimerAttributes.ContentState(
            timerStartTime: Date(), //.addingTimeInterval(-1440),
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
