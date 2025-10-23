//
//  TimerSessionManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation

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
        } else {
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
