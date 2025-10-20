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
            print("[TimerSession]  Failed to create App Group UserDefaults, falling back to standard")
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
        let targetEndTime: Date  // 타이머 종료 시간
        let pausedAt: Date?  // 일시정지 시간 (nil이면 실행 중)
        let lastUpdateTime: Date
        let activityId: String?  // 라이브 액티비티 ID

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
        activityId: String? = nil
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
            activityId: activityId
        )

        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
            userDefaults.synchronize()
            print("[TimerSession]  Saved active session:")
            print("[TimerSession]   - sessionId: \(sessionId)")
            print("[TimerSession]   - bookTitle: \(bookTitle)")
            print("[TimerSession]   - state: \(session.state)")
            print("[TimerSession]   - targetEndTime: \(targetEndTime)")
            print("[TimerSession]   - pausedAt: \(pausedAt?.description ?? "nil")")
        } else {
            print("[TimerSession]  Failed to encode session")
        }
    }

    func getActiveSession() -> ActiveSession? {
        print("[TimerSession]  Checking for stored session...")

        guard let data = userDefaults.data(forKey: sessionKey) else {
            print("[TimerSession]  No data found for key: \(sessionKey)")
            return nil
        }

        guard let session = try? JSONDecoder().decode(ActiveSession.self, from: data) else {
            print("[TimerSession]  Failed to decode session data")
            return nil
        }

        print("[TimerSession]  Retrieved active session:")
        print("[TimerSession]   - sessionId: \(session.sessionId)")
        print("[TimerSession]   - bookId: \(session.bookId)")
        print("[TimerSession]   - bookTitle: \(session.bookTitle)")
        print("[TimerSession]   - targetEndTime: \(session.targetEndTime)")
        print("[TimerSession]   - pausedAt: \(session.pausedAt?.description ?? "nil")")
        return session
    }

    func clearActiveSession() {
        userDefaults.removeObject(forKey: sessionKey)
        print("[TimerSession]  Cleared active session")
    }

    func hasActiveSession() -> Bool {
        return getActiveSession() != nil
    }
}
