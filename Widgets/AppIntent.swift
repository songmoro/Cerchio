//
//  AppIntent.swift
//  Widgets
//
//  Created by 송재훈 on 10/3/25.
//

import WidgetKit
import AppIntents
import ActivityKit

// MARK: - Timer Session Manager (Shared)
@available(iOS 16.0, *)
final class TimerSessionManager {
    static let shared = TimerSessionManager()

    private let appGroupIdentifier = "group.com.moro.cerchio"
    private lazy var userDefaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return UserDefaults.standard
        }
        return defaults
    }()
    private let sessionKey = "current_reading_session"

    private init() {}

    struct ActiveSession: Codable {
        let sessionId: String
        let bookId: String
        let bookTitle: String
        let targetMinutes: Int
        let startTime: Date
        let targetEndTime: Date
        let pausedAt: Date?
        let lastUpdateTime: Date
        let activityId: String?
        var pausedElapsedSeconds: Int?

        var state: String {
            pausedAt != nil ? "paused" : "running"
        }
    }

    func saveActiveSession(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        startTime: Date,
        targetEndTime: Date,
        pausedAt: Date? = nil,
        activityId: String? = nil,
        pausedElapsedSeconds: Int? = nil
    ) {
        let session = ActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: startTime,
            targetEndTime: targetEndTime,
            pausedAt: pausedAt,
            lastUpdateTime: Date(),
            activityId: activityId,
            pausedElapsedSeconds: pausedElapsedSeconds
        )

        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
            userDefaults.synchronize()
        }
    }

    func getActiveSession() -> ActiveSession? {
        guard let data = userDefaults.data(forKey: sessionKey) else {
            return nil
        }

        guard let session = try? JSONDecoder().decode(ActiveSession.self, from: data) else {
            return nil
        }

        return session
    }

    func clearActiveSession() {
        userDefaults.removeObject(forKey: sessionKey)
    }

    func hasActiveSession() -> Bool {
        return getActiveSession() != nil
    }
}

// MARK: - Pause Timer Intent
@available(iOS 16.2, *)
struct PauseTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "타이머 일시정지"
    static var description = IntentDescription("독서 타이머를 일시정지합니다.")

    func perform() async throws -> some IntentResult {
        guard let session = TimerSessionManager.shared.getActiveSession() else {
            return .result()
        }

        // 경과 시간 계산
        let elapsed = Int(Date().timeIntervalSince(session.startTime))

        // 세션 업데이트 (일시정지 상태로)
        TimerSessionManager.shared.saveActiveSession(
            sessionId: session.sessionId,
            bookId: session.bookId,
            bookTitle: session.bookTitle,
            targetMinutes: session.targetMinutes,
            startTime: session.startTime,
            targetEndTime: session.targetEndTime,
            pausedAt: Date(),
            activityId: session.activityId,
            pausedElapsedSeconds: elapsed
        )

        // 라이브 액티비티 업데이트
        await updateLiveActivity(
            timerStartTime: nil,
            pausedElapsedSeconds: elapsed,
            targetSeconds: session.targetMinutes * 60,
            isPaused: true
        )

        return .result()
    }
}

// MARK: - Resume Timer Intent
@available(iOS 16.2, *)
struct ResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "타이머 재개"
    static var description = IntentDescription("독서 타이머를 재개합니다.")

    func perform() async throws -> some IntentResult {
        guard let session = TimerSessionManager.shared.getActiveSession(),
              let pausedElapsed = session.pausedElapsedSeconds else {
            return .result()
        }

        // 세션 업데이트 (실행 상태로)
        TimerSessionManager.shared.saveActiveSession(
            sessionId: session.sessionId,
            bookId: session.bookId,
            bookTitle: session.bookTitle,
            targetMinutes: session.targetMinutes,
            startTime: session.startTime,
            targetEndTime: session.targetEndTime,
            pausedAt: nil,
            activityId: session.activityId,
            pausedElapsedSeconds: pausedElapsed
        )

        // 라이브 액티비티 업데이트
        await updateLiveActivity(
            timerStartTime: Date(),
            pausedElapsedSeconds: pausedElapsed,
            targetSeconds: session.targetMinutes * 60,
            isPaused: false
        )

        return .result()
    }
}

// MARK: - Cancel Timer Intent
@available(iOS 16.2, *)
struct CancelTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "타이머 취소"
    static var description = IntentDescription("독서 타이머를 취소합니다.")

    func perform() async throws -> some IntentResult {
        // 세션 삭제
        TimerSessionManager.shared.clearActiveSession()

        // 라이브 액티비티 종료
        await endAllActivities()

        return .result()
    }
}

// MARK: - Helper Functions
@available(iOS 16.2, *)
private func updateLiveActivity(
    timerStartTime: Date?,
    pausedElapsedSeconds: Int,
    targetSeconds: Int,
    isPaused: Bool
) async {
    let activities = Activity<ReadingTimerAttributes>.activities

    guard let activity = activities.first else {
        return
    }

    let newState = ReadingTimerAttributes.ContentState(
        timerStartTime: timerStartTime,
        pausedElapsedSeconds: pausedElapsedSeconds,
        targetSeconds: targetSeconds,
        isPaused: isPaused,
        isCompleted: false
    )

    let staleDate = timerStartTime?.addingTimeInterval(TimeInterval(targetSeconds - pausedElapsedSeconds))

    await activity.update(.init(state: newState, staleDate: staleDate))
}

@available(iOS 16.2, *)
private func endAllActivities() async {
    let activities = Activity<ReadingTimerAttributes>.activities

    for activity in activities {
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
