//
//  ReadingTimerReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import ReactorKit
import RxSwift
import RxCocoa
import FirebaseAnalytics

final class ReadingTimerReactor: Reactor {
    
    // MARK: - Action
    enum Action {
        case viewDidLoad
        case requestTimerStart
        case startTimerConfirmed
        case pauseTimer
        case resumeTimer
        case stopTimer
        case timerTick
        case enterBackground
        case enterForeground
        case setSession(RealmReadingSession)
        case checkDuplicateSession
        case terminateExistingSessionAndStart
        case setElapsedSeconds(Int)
        case setRemainingSeconds(Int)
        case setTimerState(TimerStateManager.TimerState)
    }
    
    // MARK: - Mutation
    enum Mutation {
        case setSession(RealmReadingSession)
        case setTimerState(TimerStateManager.TimerState)
        case setElapsedSeconds(Int)
        case setRemainingSeconds(Int)
        case setValidationError(ValidationError)
        case clearValidationError
        case setDuplicateSessionInfo(TimerSessionManager.ActiveSession?)
        case setError(Error)
    }
    
    // MARK: - State
    enum ValidationError: Error, Equatable {
        case notificationPermissionDenied
        case liveActivityNotEnabled
        case sessionTooShort
    }
    
    struct State {
        var session: RealmReadingSession?
        var timerState: TimerStateManager.TimerState = .idle
        var elapsedSeconds: Int = 0
        var remainingSeconds: Int = 0
        var targetMinutes: Int = 25
        var bookId: String
        var bookTitle: String
        var validationError: ValidationError?
        var duplicateSessionInfo: TimerSessionManager.ActiveSession?
        
        var elapsedTimeString: String {
            formatTime(elapsedSeconds)
        }
        
        var remainingTimeString: String {
            formatTime(remainingSeconds)
        }
        
        var progress: Double {
            let totalSeconds = targetMinutes * 60
            return totalSeconds > 0 ? Double(elapsedSeconds) / Double(totalSeconds) : 0
        }
        
        private func formatTime(_ seconds: Int) -> String {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
    
    // MARK: - Properties
    let initialState: State
    private let service: ReadingTimerService
    private let disposeBag = DisposeBag()

    // Timer tick
    private var timerDisposable: Disposable?

    // Analytics tracking
    private var sessionStartDate: Date?
    private var pauseCount: Int = 0
    private var totalPauseDuration: TimeInterval = 0
    private var lastPauseStartTime: Date?
    private var backgroundEnterTime: Date?
    private var totalBackgroundDuration: TimeInterval = 0
    
    // MARK: - Initialization
    
    /// 새로운 타이머 생성
    init(
        bookId: String,
        bookTitle: String,
        targetMinutes: Int,
        sessionRepository: ReadingSessionRepositoryProtocol
    ) {
        let sessionId = UUID().uuidString
        let sessionStartTime = Date()
        
        self.service = ReadingTimerService(
            sessionId: sessionId,
            bookId: bookId,
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime,
            sessionRepository: sessionRepository
        )
        
        self.initialState = State(
            remainingSeconds: targetMinutes * 60,
            targetMinutes: targetMinutes,
            bookId: bookId,
            bookTitle: bookTitle
        )
    }

    /// 세션 복원
    init(
        session: TimerSessionManager.ActiveSession,
        sessionRepository: ReadingSessionRepositoryProtocol
    ) {
        self.service = ReadingTimerService(
            sessionId: session.sessionId,
            bookId: session.bookId,
            bookTitle: session.bookTitle,
            targetMinutes: session.targetMinutes,
            sessionStartTime: session.startTime,
            sessionRepository: sessionRepository
        )

        let targetSeconds = session.targetMinutes * 60

        self.initialState = State(
            timerState: .paused,
            elapsedSeconds: 0,
            remainingSeconds: targetSeconds,
            targetMinutes: session.targetMinutes,
            bookId: session.bookId,
            bookTitle: session.bookTitle
        )

        // 세션 복원 로직 실행
        service.restore(session: session)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }

                let elapsed = self.service.stateManager.currentElapsedSeconds
                self.action.onNext(.setElapsedSeconds(elapsed))
                self.action.onNext(.setRemainingSeconds(result.remaining))

                if result.isCompleted {
                    // 타이머가 이미 완료된 경우
                    self.action.onNext(.setTimerState(.completed))
                    DebugLogger.shared.debug("세션 복구 완료 - 타이머 이미 완료됨", category: "ReadingTimer")
                } else if result.shouldAutoResume {
                    // 실행 중이었던 경우 자동 재개
                    self.action.onNext(.setTimerState(.running))
                    self.startTimerTick()
                } else {
                    // 일시정지 상태로 복원
                    self.action.onNext(.setTimerState(.paused))
                }
            }, onError: { error in
                DebugLogger.shared.debug("세션 복구 에러, \(error)", category: "ReadingTimer")
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Mutation

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return service.createRealmSession()
                .map { .setSession($0) }
                .catch { error in
                    DebugLogger.shared.debug("세션 생성 에러, \(error)", category: "ReadingTimer")
                    return .just(.setError(error))
                }

        case .requestTimerStart:
            // 중복 세션 확인
            if let duplicate = service.checkDuplicateSession() {
                return .just(.setDuplicateSessionInfo(duplicate))
            }

            Analytics.logEvent("timer_start_requested", parameters: [
                "book_title": currentState.bookTitle,
                "target_minutes": currentState.targetMinutes
            ])

            // 타이머 시작
            return service.start()
                .flatMap { [weak self] result -> Observable<Mutation> in
                    guard let self = self else { return .empty() }

                    // 사용자 확인이 필요한 경우
                    if let error = result.needsUserConfirmation {
                        let validationError: ValidationError = error == .notificationPermissionDenied
                            ? .notificationPermissionDenied
                            : .liveActivityNotEnabled

                        Analytics.logEvent("timer_start_failed", parameters: [
                            "error_type": error == .notificationPermissionDenied ? "notification_denied" : "live_activity_disabled"
                        ])

                        return .just(.setValidationError(validationError))
                    }

                    // 타이머 시작 성공
                    self.sessionStartDate = Date()
                    self.pauseCount = 0
                    self.totalPauseDuration = 0
                    self.totalBackgroundDuration = 0

                    Analytics.logEvent("timer_started", parameters: [
                        "book_id": self.currentState.bookId,
                        "book_title": self.currentState.bookTitle,
                        "target_minutes": self.currentState.targetMinutes,
                        "target_seconds": self.currentState.targetMinutes * 60,
                        "session_start_time": ISO8601DateFormatter().string(from: Date())
                    ])

                    self.startTimerTick()
                    return .just(.setTimerState(.running))
                }
                .catch { error in
                    DebugLogger.shared.debug("세션 시작 에러, \(error)", category: "ReadingTimer")

                    Analytics.logEvent("timer_start_error", parameters: [
                        "error_description": error.localizedDescription
                    ])

                    return .just(.setError(error))
                }

        case .startTimerConfirmed:
            // 권한 확인 없이 바로 시작
            return service.start()
                .do(onNext: { [weak self] _ in
                    self?.startTimerTick()
                })
                .map { _ in .setTimerState(.running) }
                .catch { error in
                    DebugLogger.shared.debug("세션 시작 에러, \(error)", category: "ReadingTimer")
                    return .just(.setError(error))
                }

        case .pauseTimer:
            stopTimerTick()

            pauseCount += 1
            lastPauseStartTime = Date()

            let totalSessionTime = sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0

            Analytics.logEvent("timer_paused", parameters: [
                "book_id": currentState.bookId,
                "book_title": currentState.bookTitle,
                "elapsed_seconds": currentState.elapsedSeconds,
                "remaining_seconds": currentState.remainingSeconds,
                "target_minutes": currentState.targetMinutes,
                "pause_count": pauseCount,
                "total_session_time": Int(totalSessionTime),
                "completion_percentage": Int(currentState.progress * 100),
                "pause_timestamp": ISO8601DateFormatter().string(from: Date())
            ])

            return service.pause()
                .map { .setTimerState(.paused) }
                .catch { error in
                    DebugLogger.shared.debug("세션 일시정지 에러, \(error)", category: "ReadingTimer")
                    return .just(.setError(error))
                }

        case .resumeTimer:
            startTimerTick()

            if let pauseStart = lastPauseStartTime {
                let pauseDuration = Date().timeIntervalSince(pauseStart)
                totalPauseDuration += pauseDuration
                lastPauseStartTime = nil
            }

            let totalSessionTime = sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0

            Analytics.logEvent("timer_resumed", parameters: [
                "book_id": currentState.bookId,
                "book_title": currentState.bookTitle,
                "elapsed_seconds": currentState.elapsedSeconds,
                "remaining_seconds": currentState.remainingSeconds,
                "target_minutes": currentState.targetMinutes,
                "pause_count": pauseCount,
                "total_pause_duration": Int(totalPauseDuration),
                "total_session_time": Int(totalSessionTime),
                "completion_percentage": Int(currentState.progress * 100),
                "resume_timestamp": ISO8601DateFormatter().string(from: Date())
            ])

            return service.resume()
                .map { .setTimerState(.running) }
                .catch { error in
                    DebugLogger.shared.debug("세션 재개 에러, \(error)")
                    return .just(.setError(error))
                }

        case .stopTimer:
            stopTimerTick()

            let totalSessionTime = sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0
            let actualReadingTime = totalSessionTime - totalPauseDuration - totalBackgroundDuration

            Analytics.logEvent("timer_stopped", parameters: [
                "book_id": currentState.bookId,
                "book_title": currentState.bookTitle,
                "elapsed_seconds": currentState.elapsedSeconds,
                "remaining_seconds": currentState.remainingSeconds,
                "target_minutes": currentState.targetMinutes,
                "target_seconds": currentState.targetMinutes * 60,
                "completion_percentage": Int(currentState.progress * 100),
                "pause_count": pauseCount,
                "total_pause_duration": Int(totalPauseDuration),
                "total_background_duration": Int(totalBackgroundDuration),
                "total_session_time": Int(totalSessionTime),
                "actual_reading_time": Int(actualReadingTime),
                "stop_timestamp": ISO8601DateFormatter().string(from: Date()),
                "is_manual_stop": true
            ])

            return service.stop(realmSession: currentState.session)
                .map { .setTimerState(.completed) }
                .catch { [weak self] error in
                    DebugLogger.shared.debug("세션 정지 에러, \(error)", category: "ReadingTimer")

                    if let stopError = error as? TimerStopUseCase.StopError,
                       case .sessionTooShort = stopError {
                        Analytics.logEvent("timer_stop_failed", parameters: [
                            "error_type": "session_too_short",
                            "elapsed_seconds": self?.currentState.elapsedSeconds ?? 0,
                            "minimum_required": 58,
                            "pause_count": self?.pauseCount ?? 0,
                            "total_pause_duration": Int(self?.totalPauseDuration ?? 0)
                        ])
                        return .just(.setValidationError(.sessionTooShort))
                    }

                    return .concat([
                        .just(.setError(error)),
                        .just(.setTimerState(.completed))
                    ])
                }

        case .timerTick:
            return service.tick()
                .flatMap { [weak self] isCompleted -> Observable<Mutation> in
                    guard let self = self else { return .empty() }

                    let elapsed = self.service.stateManager.currentElapsedSeconds
                    let remaining = self.service.stateManager.currentRemainingSeconds

                    if isCompleted {
                        let totalSessionTime = self.sessionStartDate.map { Date().timeIntervalSince($0) } ?? 0
                        let actualReadingTime = totalSessionTime - self.totalPauseDuration - self.totalBackgroundDuration

                        Analytics.logEvent("timer_completed", parameters: [
                            "book_id": self.currentState.bookId,
                            "book_title": self.currentState.bookTitle,
                            "elapsed_seconds": elapsed,
                            "target_minutes": self.currentState.targetMinutes,
                            "target_seconds": self.currentState.targetMinutes * 60,
                            "pause_count": self.pauseCount,
                            "total_pause_duration": Int(self.totalPauseDuration),
                            "total_background_duration": Int(self.totalBackgroundDuration),
                            "total_session_time": Int(totalSessionTime),
                            "actual_reading_time": Int(actualReadingTime),
                            "completion_timestamp": ISO8601DateFormatter().string(from: Date()),
                            "is_auto_complete": true
                        ])

                        self.stopTimerTick()
                        return self.service.stop(realmSession: self.currentState.session)
                            .flatMap { _ -> Observable<Mutation> in
                                return .concat([
                                    .just(.setElapsedSeconds(elapsed)),
                                    .just(.setRemainingSeconds(remaining)),
                                    .just(.setTimerState(.completed))
                                ])
                            }
                    }

                    return .concat([
                        .just(.setElapsedSeconds(elapsed)),
                        .just(.setRemainingSeconds(remaining))
                    ])
                }

        case .enterBackground:
            backgroundEnterTime = Date()

            Analytics.logEvent("timer_background_entered", parameters: [
                "book_id": currentState.bookId,
                "elapsed_seconds": currentState.elapsedSeconds,
                "remaining_seconds": currentState.remainingSeconds,
                "timer_state": currentState.timerState == .running ? "running" : "paused",
                "background_enter_timestamp": ISO8601DateFormatter().string(from: Date())
            ])

            return service.enterBackground()
                .flatMap { _ in Observable<Mutation>.empty() }

        case .enterForeground:
            if let bgEnterTime = backgroundEnterTime {
                let bgDuration = Date().timeIntervalSince(bgEnterTime)
                totalBackgroundDuration += bgDuration
                backgroundEnterTime = nil
            }

            return service.enterForeground()
                .flatMap { [weak self] result -> Observable<Mutation> in
                    guard let self = self else { return .empty() }

                    let elapsed = self.service.stateManager.currentElapsedSeconds
                    let remaining = self.service.stateManager.currentRemainingSeconds

                    let resultType: String
                    switch result {
                    case .completed:
                        resultType = "completed"
                        self.stopTimerTick()

                        Analytics.logEvent("timer_foreground_entered", parameters: [
                            "book_id": self.currentState.bookId,
                            "elapsed_seconds": elapsed,
                            "remaining_seconds": remaining,
                            "result_type": resultType,
                            "total_background_duration": Int(self.totalBackgroundDuration),
                            "foreground_enter_timestamp": ISO8601DateFormatter().string(from: Date())
                        ])

                        return self.service.stop(realmSession: self.currentState.session)
                            .map { _ in .setTimerState(.completed) }

                    case .paused:
                        resultType = "paused"

                        Analytics.logEvent("timer_foreground_entered", parameters: [
                            "book_id": self.currentState.bookId,
                            "elapsed_seconds": elapsed,
                            "remaining_seconds": remaining,
                            "result_type": resultType,
                            "total_background_duration": Int(self.totalBackgroundDuration),
                            "foreground_enter_timestamp": ISO8601DateFormatter().string(from: Date())
                        ])

                        return .concat([
                            .just(.setElapsedSeconds(elapsed)),
                            .just(.setRemainingSeconds(remaining))
                        ])

                    case .updated:
                        resultType = "updated"
                        self.startTimerTick()

                        Analytics.logEvent("timer_foreground_entered", parameters: [
                            "book_id": self.currentState.bookId,
                            "elapsed_seconds": elapsed,
                            "remaining_seconds": remaining,
                            "result_type": resultType,
                            "total_background_duration": Int(self.totalBackgroundDuration),
                            "foreground_enter_timestamp": ISO8601DateFormatter().string(from: Date())
                        ])

                        return .concat([
                            .just(.setElapsedSeconds(elapsed)),
                            .just(.setRemainingSeconds(remaining))
                        ])
                    }
                }

        case .setSession(let session):
            return .just(.setSession(session))

        case .checkDuplicateSession:
            if let duplicate = service.checkDuplicateSession() {
                return .just(.setDuplicateSessionInfo(duplicate))
            }
            return .empty()

        case .terminateExistingSessionAndStart:
            return service.terminateExistingAndStart()
                .do(onNext: { [weak self] _ in
                    self?.startTimerTick()
                })
                .map { _ in .setTimerState(.running) }

        case .setElapsedSeconds(let seconds):
            return .just(.setElapsedSeconds(seconds))

        case .setRemainingSeconds(let seconds):
            return .just(.setRemainingSeconds(seconds))
            
        case .setTimerState(let state):
            return .just(.setTimerState(state))
        }
    }

    // MARK: - Reduce

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSession(let session):
            newState.session = session
            
        case .setTimerState(let timerState):
            newState.timerState = timerState
            
        case .setElapsedSeconds(let seconds):
            newState.elapsedSeconds = seconds
            
        case .setRemainingSeconds(let seconds):
            newState.remainingSeconds = seconds
            
        case .setValidationError(let error):
            newState.validationError = error
            
        case .clearValidationError:
            newState.validationError = nil
            
        case .setDuplicateSessionInfo(let info):
            newState.duplicateSessionInfo = info
            
        case .setError:
            break
        }
        return newState
    }

    // MARK: - Timer Tick

    private func startTimerTick() {
        stopTimerTick()

        timerDisposable = Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .startWith(0)  // 즉시 첫 틱 발생
            .map { _ in Action.timerTick }
            .bind(to: action)
    }

    private func stopTimerTick() {
        timerDisposable?.dispose()
        timerDisposable = nil
    }

    // MARK: - Deinit
    deinit {
        stopTimerTick()
    }
}
