//
//  ReadingTimerService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class ReadingTimerService {

    let stateManager: TimerStateManager
    let activityManager: TimerActivityManager
    private let lifecycleManager: TimerLifecycleManager
    private let validationService: TimerValidationService
    private let notificationManager: TimerNotificationManager
    private let sessionManager: TimerSessionManager
    private let sessionRepository: ReadingSessionRepositoryProtocol

    private let startUseCase: TimerStartUseCase
    private let pauseUseCase: TimerPauseUseCase
    private let resumeUseCase: TimerResumeUseCase
    private let stopUseCase: TimerStopUseCase
    private let tickUseCase: TimerTickUseCase
    private let backgroundUseCase: TimerBackgroundUseCase
    private let foregroundUseCase: TimerForegroundUseCase
    private let restoreUseCase: TimerRestoreUseCase

    private let sessionId: String
    private let bookId: String
    private let bookTitle: String
    private let targetMinutes: Int
    private var sessionStartTime: Date

    init(
        sessionId: String,
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date,
        sessionRepository: ReadingSessionRepositoryProtocol
    ) {
        self.sessionId = sessionId
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.targetMinutes = targetMinutes
        self.sessionStartTime = sessionStartTime
        self.sessionRepository = sessionRepository

        self.stateManager = TimerStateManager(targetMinutes: targetMinutes)
        self.lifecycleManager = TimerLifecycleManager(
            targetSeconds: targetMinutes * 60
        )
        self.validationService = TimerValidationService()
        self.notificationManager = TimerNotificationManager()
        self.activityManager = TimerActivityManager()
        self.sessionManager = TimerSessionManager.shared

        self.startUseCase = TimerStartUseCase(
            validationService: validationService,
            notificationManager: notificationManager,
            activityManager: activityManager,
            sessionManager: sessionManager,
            stateManager: stateManager
        )

        self.pauseUseCase = TimerPauseUseCase(
            stateManager: stateManager,
            notificationManager: notificationManager,
            activityManager: activityManager,
            sessionManager: sessionManager
        )

        self.resumeUseCase = TimerResumeUseCase(
            stateManager: stateManager,
            notificationManager: notificationManager,
            activityManager: activityManager,
            sessionManager: sessionManager
        )

        self.stopUseCase = TimerStopUseCase(
            stateManager: stateManager,
            validationService: validationService,
            notificationManager: notificationManager,
            activityManager: activityManager,
            sessionManager: sessionManager,
            sessionRepository: sessionRepository
        )

        self.tickUseCase = TimerTickUseCase(
            stateManager: stateManager,
            sessionManager: sessionManager
        )

        self.backgroundUseCase = TimerBackgroundUseCase(
            stateManager: stateManager,
            sessionManager: sessionManager
        )

        self.foregroundUseCase = TimerForegroundUseCase(
            stateManager: stateManager,
            lifecycleManager: lifecycleManager,
            activityManager: activityManager,
            notificationManager: notificationManager,
            sessionManager: sessionManager
        )

        self.restoreUseCase = TimerRestoreUseCase(
            stateManager: stateManager,
            lifecycleManager: lifecycleManager,
            activityManager: activityManager,
            sessionRepository: sessionRepository
        )
    }

    func start() -> Observable<TimerStartUseCase.StartResult> {
        return startUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes
        )
        .do(onNext: { [weak self] result in
            self?.sessionStartTime = result.startTime
        })
    }

    func pause() -> Observable<Void> {
        return pauseUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    func resume() -> Observable<Void> {
        return resumeUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    func stop(realmSession: RealmReadingSession?) -> Observable<Void> {
        return stopUseCase.execute(
            sessionId: sessionId,
            realmSession: realmSession
        )
    }

    func tick() -> Observable<Bool> {
        return tickUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    func enterBackground() -> Observable<Void> {
        return backgroundUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    func enterForeground() -> Observable<TimerForegroundUseCase.ForegroundResult> {
        return foregroundUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    func restore(session: TimerSessionManager.ActiveSession) -> Observable<TimerRestoreUseCase.RestoreResult> {
        return restoreUseCase.execute(
            session: session,
            sessionStartTime: sessionStartTime
        )
    }

    func checkDuplicateSession() -> TimerSessionManager.ActiveSession? {
        return validationService.checkDuplicateSession()
    }

    func terminateExistingAndStart() -> Observable<TimerStartUseCase.StartResult> {
        sessionManager.clearActiveSession()
        if #available(iOS 16.2, *) {
            _ = activityManager.end().subscribe()
        }
        return start()
    }

    func createRealmSession() -> Observable<RealmReadingSession> {
        let session = RealmReadingSession(
            id: sessionId,
            bookId: bookId,
            startTime: sessionStartTime,
            targetMinutes: targetMinutes,
            status: .inProgress
        )

        return sessionRepository.saveSession(session)
            .do(onNext: { savedSession in
            })
    }

    var activityDismissed: Observable<Void> {
        activityManager.activityDismissed
    }

    var activityStale: Observable<Void> {
        activityManager.activityStale
    }

    var activityEnded: Observable<Void> {
        activityManager.activityEnded
    }
}
