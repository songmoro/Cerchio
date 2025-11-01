//
//  TimerSessionManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import RxSwift
import RxRelay

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

    // Darwin Notification 이벤트
    private let pauseEventRelay = PublishRelay<Void>()
    private let resumeEventRelay = PublishRelay<Void>()
    private let cancelEventRelay = PublishRelay<Void>()

    var pauseEvent: Observable<Void> { pauseEventRelay.asObservable() }
    var resumeEvent: Observable<Void> { resumeEventRelay.asObservable() }
    var cancelEvent: Observable<Void> { cancelEventRelay.asObservable() }

    private init() {
        setupDarwinNotificationObservers()
    }

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

    // MARK: - Darwin Notification Setup

    private func setupDarwinNotificationObservers() {
        // Pause 알림 관찰
        let pauseCallback: CFNotificationCallback = { _, observer, name, _, _ in
            guard let observer = observer else { return }
            let mySelf = Unmanaged<TimerSessionManager>.fromOpaque(observer).takeUnretainedValue()
            mySelf.pauseEventRelay.accept(())
        }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            pauseCallback,
            "com.moro.cerchio.timer.pause" as CFString,
            nil,
            .deliverImmediately
        )

        // Resume 알림 관찰
        let resumeCallback: CFNotificationCallback = { _, observer, name, _, _ in
            guard let observer = observer else { return }
            let mySelf = Unmanaged<TimerSessionManager>.fromOpaque(observer).takeUnretainedValue()
            mySelf.resumeEventRelay.accept(())
        }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            resumeCallback,
            "com.moro.cerchio.timer.resume" as CFString,
            nil,
            .deliverImmediately
        )

        // Cancel 알림 관찰
        let cancelCallback: CFNotificationCallback = { _, observer, name, _, _ in
            guard let observer = observer else { return }
            let mySelf = Unmanaged<TimerSessionManager>.fromOpaque(observer).takeUnretainedValue()
            mySelf.cancelEventRelay.accept(())
        }

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            cancelCallback,
            "com.moro.cerchio.timer.cancel" as CFString,
            nil,
            .deliverImmediately
        )
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque()
        )
    }
}
