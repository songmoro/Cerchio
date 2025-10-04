//
//  TimerSessionManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation

final class TimerSessionManager {

    static let shared = TimerSessionManager()

    // App Group identifier - 앱과 위젯 간 데이터 공유
    private let appGroupIdentifier = "group.com.moro.cerchio"
    private lazy var userDefaults: UserDefaults = {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("[TimerSession] ⚠️ Failed to create App Group UserDefaults, falling back to standard")
            return UserDefaults.standard
        }
        return defaults
    }()
    private let sessionKey = "current_reading_session"

    private init() {}

    // MARK: - Active Session

    struct ActiveSession: Codable {
        let sessionId: String
        let bookId: String
        let bookTitle: String
        let targetMinutes: Int
        let startTime: Date
        let elapsedSeconds: Int
        let pausedDuration: Int  // 총 일시정지 시간 (초)
        let pauseStartTime: Date?  // 일시정지 시작 시간
        let state: String  // "running", "paused"
        let lastUpdateTime: Date
        let activityId: String?  // 라이브 액티비티 ID
    }

    func saveActiveSession(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        startTime: Date,
        elapsedSeconds: Int = 0,
        pausedDuration: Int = 0,
        pauseStartTime: Date? = nil,
        state: String = "running",
        activityId: String? = nil
    ) {
        let session = ActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: startTime,
            elapsedSeconds: elapsedSeconds,
            pausedDuration: pausedDuration,
            pauseStartTime: pauseStartTime,
            state: state,
            lastUpdateTime: Date(),
            activityId: activityId
        )

        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
            userDefaults.synchronize()
            print("[TimerSession] 💾 Saved active session:")
            print("[TimerSession]   - sessionId: \(sessionId)")
            print("[TimerSession]   - bookTitle: \(bookTitle)")
            print("[TimerSession]   - state: \(state)")
            print("[TimerSession]   - elapsedSeconds: \(elapsedSeconds)")
            print("[TimerSession]   - pausedDuration: \(pausedDuration)")
        } else {
            print("[TimerSession] ❌ Failed to encode session")
        }
    }

    func getActiveSession() -> ActiveSession? {
        print("[TimerSession] 🔍 Checking for stored session...")

        guard let data = userDefaults.data(forKey: sessionKey) else {
            print("[TimerSession] ❌ No data found for key: \(sessionKey)")
            return nil
        }

        guard let session = try? JSONDecoder().decode(ActiveSession.self, from: data) else {
            print("[TimerSession] ❌ Failed to decode session data")
            return nil
        }

        print("[TimerSession] ✅ Retrieved active session:")
        print("[TimerSession]   - sessionId: \(session.sessionId)")
        print("[TimerSession]   - bookId: \(session.bookId)")
        print("[TimerSession]   - bookTitle: \(session.bookTitle)")
        print("[TimerSession]   - elapsedSeconds: \(session.elapsedSeconds)")
        return session
    }

    func clearActiveSession() {
        userDefaults.removeObject(forKey: sessionKey)
        print("[TimerSession] 🗑️ Cleared active session")
    }

    func updateElapsedTime(elapsedSeconds: Int) {
        guard let session = getActiveSession() else { return }

        let updatedSession = ActiveSession(
            sessionId: session.sessionId,
            bookId: session.bookId,
            bookTitle: session.bookTitle,
            targetMinutes: session.targetMinutes,
            startTime: session.startTime,
            elapsedSeconds: elapsedSeconds,
            pausedDuration: session.pausedDuration,
            pauseStartTime: session.pauseStartTime,
            state: session.state,
            lastUpdateTime: Date(),
            activityId: session.activityId
        )

        if let encoded = try? JSONEncoder().encode(updatedSession) {
            userDefaults.set(encoded, forKey: sessionKey)
            userDefaults.synchronize()
        }
    }

    func hasActiveSession() -> Bool {
        return getActiveSession() != nil
    }
}
