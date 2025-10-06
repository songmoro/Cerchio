//
//  ReadingTimerService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

/// 독서 타이머의 모든 비즈니스 로직을 통합하는 서비스
/// - 각 UseCase를 조합하여 타이머의 전체 플로우 관리
/// - Reactor는 이 서비스를 통해 간단하게 비즈니스 로직 호출
final class ReadingTimerService {

    // MARK: - Properties

    // Core managers
    let stateManager: TimerStateManager
    private let lifecycleManager: TimerLifecycleManager
    private let validationService: TimerValidationService
    private let notificationManager: TimerNotificationManager
    private let activityManager: TimerActivityManager
    private let sessionManager: TimerSessionManager
    private let sessionRepository: ReadingSessionRepositoryProtocol

    // UseCases
    private let startUseCase: TimerStartUseCase
    private let pauseUseCase: TimerPauseUseCase
    private let resumeUseCase: TimerResumeUseCase
    private let stopUseCase: TimerStopUseCase
    private let tickUseCase: TimerTickUseCase
    private let backgroundUseCase: TimerBackgroundUseCase
    private let foregroundUseCase: TimerForegroundUseCase
    private let restoreUseCase: TimerRestoreUseCase

    // Session info
    private let sessionId: String
    private let bookId: String
    private let bookTitle: String
    private let targetMinutes: Int
    private let sessionStartTime: Date

    // MARK: - Initialization

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

        // Initialize managers
        self.stateManager = TimerStateManager(targetMinutes: targetMinutes)
        self.lifecycleManager = TimerLifecycleManager(
            targetSeconds: targetMinutes * 60
        )
        self.validationService = TimerValidationService()
        self.notificationManager = TimerNotificationManager()
        self.activityManager = TimerActivityManager()
        self.sessionManager = TimerSessionManager.shared

        // Initialize UseCases
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

    // MARK: - UseCase Execution

    /// 타이머 시작
    func start() -> Observable<TimerStartUseCase.StartResult> {
        return startUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes
        )
    }

    /// 일시정지
    func pause() -> Observable<Void> {
        return pauseUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    /// 재개
    func resume() -> Observable<Void> {
        return resumeUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    /// 정지 및 저장
    func stop(realmSession: RealmReadingSession?) -> Observable<Void> {
        return stopUseCase.execute(
            sessionId: sessionId,
            realmSession: realmSession
        )
    }

    /// 1초 틱
    func tick() -> Observable<Bool> {
        return tickUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    /// 백그라운드 진입
    func enterBackground() -> Observable<Void> {
        return backgroundUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    /// 포그라운드 복귀
    func enterForeground() -> Observable<TimerForegroundUseCase.ForegroundResult> {
        return foregroundUseCase.execute(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime
        )
    }

    /// 세션 복원
    func restore(session: TimerSessionManager.ActiveSession) -> Observable<TimerRestoreUseCase.RestoreResult> {
        return restoreUseCase.execute(
            session: session,
            sessionStartTime: sessionStartTime
        )
    }

    // MARK: - Validation

    /// 중복 세션 확인
    func checkDuplicateSession() -> TimerSessionManager.ActiveSession? {
        return validationService.checkDuplicateSession()
    }

    /// 기존 세션 종료 후 새로 시작
    func terminateExistingAndStart() -> Observable<TimerStartUseCase.StartResult> {
        sessionManager.clearActiveSession()
        if #available(iOS 16.2, *) {
            _ = activityManager.end().subscribe()
        }
        return start()
    }

    // MARK: - Session Management

    /// Realm 세션 생성
    func createRealmSession() -> Observable<RealmReadingSession> {
        let session = RealmReadingSession(
            id: sessionId,
            bookId: bookId,
            startTime: sessionStartTime,
            targetMinutes: targetMinutes,
            status: .inProgress
        )

        print("[ReadingTimerService] 💾 Creating Realm session: \(sessionId)")

        return sessionRepository.saveSession(session)
            .do(onNext: { savedSession in
                print("[ReadingTimerService] ✅ Realm session created: \(savedSession.id)")
            })
    }

    // MARK: - Activity Monitoring

    /// Live Activity 이벤트 구독
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
