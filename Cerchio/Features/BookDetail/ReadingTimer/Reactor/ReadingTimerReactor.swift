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

        setupActivityMonitoring()
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

        // 세션 복원 실행
        restoreSession(session)
        setupActivityMonitoring()
    }

    // MARK: - Mutation

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return service.createRealmSession()
                .map { .setSession($0) }
                .catch { error in
                    print("[Reactor] ❌ Failed to create session: \(error)")
                    return .just(.setError(error))
                }

        case .requestTimerStart:
            // 중복 세션 확인
            if let duplicate = service.checkDuplicateSession() {
                return .just(.setDuplicateSessionInfo(duplicate))
            }

            // 타이머 시작
            return service.start()
                .flatMap { [weak self] result -> Observable<Mutation> in
                    guard let self = self else { return .empty() }

                    // 사용자 확인이 필요한 경우
                    if let error = result.needsUserConfirmation {
                        let validationError: ValidationError = error == .notificationPermissionDenied
                            ? .notificationPermissionDenied
                            : .liveActivityNotEnabled
                        return .just(.setValidationError(validationError))
                    }

                    // 타이머 시작 성공
                    self.startTimerTick()
                    return .just(.setTimerState(.running))
                }
                .catch { error in
                    print("[Reactor] ❌ Start failed: \(error)")
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
                    print("[Reactor] ❌ Confirmed start failed: \(error)")
                    return .just(.setError(error))
                }

        case .pauseTimer:
            stopTimerTick()
            return service.pause()
                .map { .setTimerState(.paused) }
                .catch { error in
                    print("[Reactor] ❌ Pause failed: \(error)")
                    return .just(.setError(error))
                }

        case .resumeTimer:
            startTimerTick()
            return service.resume()
                .map { .setTimerState(.running) }
                .catch { error in
                    print("[Reactor] ❌ Resume failed: \(error)")
                    return .just(.setError(error))
                }

        case .stopTimer:
            stopTimerTick()
            return service.stop(realmSession: currentState.session)
                .map { .setTimerState(.completed) }
                .catch { error in
                    if let stopError = error as? TimerStopUseCase.StopError,
                       case .sessionTooShort = stopError {
                        return .just(.setValidationError(.sessionTooShort))
                    }
                    print("[Reactor] ❌ Stop failed: \(error)")
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
            return service.enterBackground()
                .flatMap { _ in Observable<Mutation>.empty() }

        case .enterForeground:
            return service.enterForeground()
                .flatMap { [weak self] result -> Observable<Mutation> in
                    guard let self = self else { return .empty() }

                    let elapsed = self.service.stateManager.currentElapsedSeconds
                    let remaining = self.service.stateManager.currentRemainingSeconds

                    switch result {
                    case .completed:
                        self.stopTimerTick()
                        return self.service.stop(realmSession: self.currentState.session)
                            .map { _ in .setTimerState(.completed) }

                    case .paused:
                        return .concat([
                            .just(.setElapsedSeconds(elapsed)),
                            .just(.setRemainingSeconds(remaining))
                        ])

                    case .updated:
                        self.startTimerTick()
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
            .map { _ in Action.timerTick }
            .bind(to: action)
    }

    private func stopTimerTick() {
        timerDisposable?.dispose()
        timerDisposable = nil
    }

    // MARK: - Session Restore

    private func restoreSession(_ session: TimerSessionManager.ActiveSession) {
        service.restore(session: session)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] result in
                    guard let self = self else { return }

                    print("[Reactor] 🔄 Session restore completed")
                    print("  - remaining: \(result.remaining)")
                    print("  - shouldAutoResume: \(result.shouldAutoResume)")

                    // 상태 업데이트
                    let elapsed = self.service.stateManager.currentElapsedSeconds
                    self.action.onNext(.setElapsedSeconds(elapsed))
                    self.action.onNext(.setRemainingSeconds(result.remaining))

                    // 자동 재개
                    if result.shouldAutoResume {
                        print("[Reactor] ⏰ Auto-resuming timer")
                        self.action.onNext(.resumeTimer)
                    }
                },
                onError: { error in
                    print("[Reactor] ❌ Session restore failed: \(error)")
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Activity Monitoring

    private func setupActivityMonitoring() {
        guard #available(iOS 16.2, *) else { return }

        // Stale 이벤트
        service.activityStale
            .subscribe(onNext: { [weak self] in
                print("[Reactor] ⏰ Live Activity became stale - will recreate on next action")
            })
            .disposed(by: disposeBag)

        // Dismissed 이벤트
        service.activityDismissed
            .subscribe(onNext: { [weak self] in
                print("[Reactor] 🗑️ User dismissed Live Activity")
            })
            .disposed(by: disposeBag)

        // Ended 이벤트
        service.activityEnded
            .subscribe(onNext: { [weak self] in
                print("[Reactor] ⏹️ Live Activity ended")
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Deinit

    deinit {
        stopTimerTick()
    }
}
