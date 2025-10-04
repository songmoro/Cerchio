//
//  TimerSessionManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation

final class TimerSessionManager {

    static let shared = TimerSessionManager()

    private let userDefaults = UserDefaults.standard
    private let sessionKey = "activeTimerSession"

    private init() {}

    // MARK: - Active Session

    struct ActiveSession: Codable {
        let sessionId: String
        let bookId: String
        let bookTitle: String
        let targetMinutes: Int
        let startTime: Date
        let elapsedSeconds: Int  // 일시정지 시점의 경과 시간
    }

    func saveActiveSession(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        startTime: Date,
        elapsedSeconds: Int = 0
    ) {
        let session = ActiveSession(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            startTime: startTime,
            elapsedSeconds: elapsedSeconds
        )

        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
            userDefaults.synchronize() // 즉시 저장
            print("[TimerSession] 💾 Saved active session:")
            print("[TimerSession]   - sessionId: \(sessionId)")
            print("[TimerSession]   - bookId: \(bookId)")
            print("[TimerSession]   - bookTitle: \(bookTitle)")
            print("[TimerSession]   - elapsedSeconds: \(elapsedSeconds)")
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
        guard var session = getActiveSession() else { return }

        session = ActiveSession(
            sessionId: session.sessionId,
            bookId: session.bookId,
            bookTitle: session.bookTitle,
            targetMinutes: session.targetMinutes,
            startTime: session.startTime,
            elapsedSeconds: elapsedSeconds
        )

        if let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
        }
    }
}
