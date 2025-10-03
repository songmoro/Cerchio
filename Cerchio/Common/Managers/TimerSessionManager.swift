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
            print("[TimerSession] 💾 Saved active session: \(sessionId)")
        }
    }

    func getActiveSession() -> ActiveSession? {
        guard let data = userDefaults.data(forKey: sessionKey),
              let session = try? JSONDecoder().decode(ActiveSession.self, from: data) else {
            return nil
        }

        print("[TimerSession] 📂 Retrieved active session: \(session.sessionId)")
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
