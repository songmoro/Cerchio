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
import UserNotifications

final class ReadingTimerReactor: Reactor {

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

    enum Mutation {
        case setSession(RealmReadingSession)
        case setTimerState(TimerState)
        case setElapsedSeconds(Int)
        case setRemainingSeconds(Int)
        case setValidationError(ValidationError)
        case clearValidationError
        case setTimerStartDate(Date?)
        case setPausedDuration(Int)
        case setPauseStartTime(Date?)
        case setDuplicateSessionInfo(TimerSessionManager.ActiveSession?)
        case setError(Error)
    }

    enum ValidationError: Error, Equatable {
        case notificationPermissionDenied
        case liveActivityNotEnabled
        case sessionTooShort
    }

    struct State {
        var session: RealmReadingSession?
        var timerState: TimerState = .idle
        var elapsedSeconds: Int = 0
        var remainingSeconds: Int = 0
        var targetMinutes: Int = 25
        var bookId: String
        var bookTitle: String
        var validationError: ValidationError?
        var timerStartDate: Date?
        var pausedDuration: Int = 0
        var pauseStartTime: Date?
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

    enum TimerState {
        case idle
        case running
        case paused
        case completed
    }

    let initialState: State
    private let sessionRepository: ReadingSessionRepositoryProtocol
    private let notificationManager = NotificationManager.shared
    private let timerSessionManager = TimerSessionManager.shared
    private let disposeBag = DisposeBag()

    // Timer management
    private var timerDisposable: Disposable?
    private var backgroundTime: Date?
    private var notificationScheduled = false
    private var liveActivityStarted = false
    private var sessionId: String
    private var scheduledNotificationId: String?

    init(bookId: String, bookTitle: String, targetMinutes: Int, sessionRepository: ReadingSessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.sessionId = UUID().uuidString
        self.initialState = State(
            remainingSeconds: targetMinutes * 60,
            targetMinutes: targetMinutes,
            bookId: bookId,
            bookTitle: bookTitle
        )

        // 라이브 액티비티 상태 모니터링
        setupActivityStateMonitoring()
    }

    // 앱 재시작 시 세션 복원용 initializer
    init(session: TimerSessionManager.ActiveSession, sessionRepository: ReadingSessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.sessionId = session.sessionId

        // 경과 시간 동기화 계산
        let savedElapsed = session.elapsedSeconds
        let timeSinceLastUpdate = Int(Date().timeIntervalSince(session.lastUpdateTime))
        let targetSeconds = session.targetMinutes * 60

        // 세션 상태에 따라 경과 시간 계산
        let calculatedElapsed: Int
        if session.state == "running" {
            // 실행 중이었으면 마지막 업데이트 이후 경과 시간 추가
            calculatedElapsed = savedElapsed + timeSinceLastUpdate
        } else {
            // 일시정지였으면 저장된 시간만 사용
            calculatedElapsed = savedElapsed
        }

        // ⚠️ 목표 시간을 초과하지 않도록 즉시 제한
        let totalElapsed = min(calculatedElapsed, targetSeconds)
        let remainingSeconds = max(0, targetSeconds - totalElapsed)

        print("[ReadingTimer] 🔄 Initializing with restored session:")
        print("[ReadingTimer]   - sessionId: \(session.sessionId)")
        print("[ReadingTimer]   - savedElapsedSeconds: \(savedElapsed)")
        print("[ReadingTimer]   - timeSinceLastUpdate: \(timeSinceLastUpdate)s")
        print("[ReadingTimer]   - session.state: \(session.state)")
        print("[ReadingTimer]   - totalElapsedSeconds: \(totalElapsed)")
        print("[ReadingTimer]   - remainingSeconds: \(remainingSeconds)")

        // 복구 시에는 항상 일시정지 상태로 시작
        self.initialState = State(
            timerState: .paused,
            elapsedSeconds: totalElapsed,
            remainingSeconds: remainingSeconds,
            targetMinutes: session.targetMinutes,
            bookId: session.bookId,
            bookTitle: session.bookTitle,
            timerStartDate: session.startTime,
            pausedDuration: session.pausedDuration
        )

        // 기존 세션 로드 시도
        loadExistingSession()

        // 라이브 액티비티 상태 모니터링
        setupActivityStateMonitoring()

        // 라이브 액티비티를 일시정지 상태로 먼저 동기화
        syncLiveActivityOnRestore(elapsedSeconds: totalElapsed, isPaused: true, targetSeconds: targetSeconds)

        // 원래 running 상태였다면 빠르게 자동 재개
        if session.state == "running" {
            print("[ReadingTimer] ⏰ Auto-resume scheduled (0.1s delay)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }

                // 재개 시점에 시간 재계산 (오차 최소화)
                let recalculatedElapsed = self.calculateCurrentElapsedTime(
                    savedElapsed: savedElapsed,
                    lastUpdateTime: session.lastUpdateTime,
                    sessionState: session.state
                )

                // ⚠️ 목표 시간을 초과하지 않도록 제한
                let targetSecs = session.targetMinutes * 60
                let currentElapsed = min(recalculatedElapsed, targetSecs)
                let remainingSecs = max(0, targetSecs - currentElapsed)

                print("[ReadingTimer] 🔄 Recalculating time at resume:")
                print("[ReadingTimer]   - initial: \(totalElapsed)s")
                print("[ReadingTimer]   - recalculated: \(recalculatedElapsed)s")
                print("[ReadingTimer]   - clamped: \(currentElapsed)s")
                print("[ReadingTimer]   - difference: \(currentElapsed - totalElapsed)s")

                self.action.onNext(.setElapsedSeconds(currentElapsed))
                self.action.onNext(.setRemainingSeconds(remainingSecs))

                // 재개
                self.action.onNext(.resumeTimer)
            }
        }
    }

    private func calculateCurrentElapsedTime(savedElapsed: Int, lastUpdateTime: Date, sessionState: String) -> Int {
        if sessionState == "running" {
            let timeSinceLastUpdate = Int(Date().timeIntervalSince(lastUpdateTime))
            return savedElapsed + timeSinceLastUpdate
        } else {
            return savedElapsed
        }
    }

    private func syncLiveActivityOnRestore(elapsedSeconds: Int, isPaused: Bool, targetSeconds: Int) {
        guard #available(iOS 16.2, *) else { return }

        let activeActivities = LiveActivityManager.shared.getActiveActivities()
        guard !activeActivities.isEmpty else {
            print("[ReadingTimer] No active Live Activity to sync")
            return
        }

        print("[ReadingTimer] 🔄 Syncing Live Activity with restored session")
        print("[ReadingTimer]   - elapsedSeconds: \(elapsedSeconds)")
        print("[ReadingTimer]   - isPaused: \(isPaused)")

        // 라이브 액티비티를 복원된 시간으로 업데이트
        LiveActivityManager.shared.updateActivity(
            elapsedSeconds: elapsedSeconds,
            isPaused: isPaused,
            targetSeconds: targetSeconds
        )
        .subscribe(
            onNext: {
                print("[ReadingTimer] ✅ Live Activity synced successfully")
            },
            onError: { error in
                print("[ReadingTimer] ❌ Failed to sync Live Activity: \(error)")
            }
        )
        .disposed(by: disposeBag)

        liveActivityStarted = true
    }

    private func loadExistingSession() {
        // RealmReadingSession 조회
        _ = sessionRepository.getSessionById(sessionId)
            .subscribe(onNext: { [weak self] realmSession in
                if let realmSession = realmSession {
                    print("[ReadingTimer] ✅ Found existing RealmSession: \(realmSession.id)")
                    self?.action.onNext(.setSession(realmSession))
                } else {
                    print("[ReadingTimer] ⚠️ No existing RealmSession found - will create new one")
                }
            })
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            // 복원된 세션인 경우 새로 생성하지 않음
            if currentState.session != nil {
                print("[ReadingTimer] 🔄 Restored session detected - skipping session creation")
                return .empty()
            }
            return createSession()

        case .requestTimerStart:
            return validateAndRequestPermissions()

        case .startTimerConfirmed:
            let startTime = Date()
            saveActiveSession(elapsedSeconds: 0, startTime: startTime)
            startTimerTick()
            startLiveActivity()
            return .concat([
                .just(.setTimerStartDate(startTime)),
                .just(.setTimerState(.running))
            ])

        case .pauseTimer:
            stopTimerTick()
            cancelNotification()
            updateLiveActivityPaused()
            let pauseTime = Date()
            saveActiveSession(
                elapsedSeconds: currentState.elapsedSeconds,
                startTime: currentState.timerStartDate ?? Date(),
                pausedDuration: currentState.pausedDuration,
                pauseStartTime: pauseTime,
                state: "paused"
            )
            return .concat([
                .just(.setPauseStartTime(pauseTime)),
                .just(.setTimerState(.paused))
            ])

        case .resumeTimer:
            // 일시정지 시간 계산
            let pauseDuration: Int
            if let pauseStart = currentState.pauseStartTime {
                pauseDuration = Int(Date().timeIntervalSince(pauseStart))
            } else {
                pauseDuration = 0
            }
            let totalPausedDuration = currentState.pausedDuration + pauseDuration

            startTimerTick()
            scheduleNotification()
            updateLiveActivityResumed()
            saveActiveSession(
                elapsedSeconds: currentState.elapsedSeconds,
                startTime: currentState.timerStartDate ?? Date(),
                pausedDuration: totalPausedDuration,
                pauseStartTime: nil,
                state: "running"
            )
            return .concat([
                .just(.setPausedDuration(totalPausedDuration)),
                .just(.setPauseStartTime(nil)),
                .just(.setTimerState(.running))
            ])

        case .stopTimer:
            stopTimerTick()
            cancelNotification()
            endLiveActivity()
            clearActiveSession()
            return completeSession()

        case .timerTick:
            let targetSeconds = currentState.targetMinutes * 60
            let newElapsed = min(currentState.elapsedSeconds + 1, targetSeconds)
            let newRemaining = max(0, targetSeconds - newElapsed)

            // Live Activity는 위젯 자체가 계산하므로 업데이트 불필요
            // 10초마다 또는 주요 이벤트(일시정지, 재개, 종료)에만 업데이트

            var mutations: [Observable<Mutation>] = [
                .just(.setElapsedSeconds(newElapsed)),
                .just(.setRemainingSeconds(newRemaining))
            ]

            // Check if timer completed
            if newRemaining == 0 {
                stopTimerTick()
                cancelNotification()
                // Live Activity 즉시 종료
                endLiveActivity()
                clearActiveSession()
                mutations.append(completeSession())
            } else {
                // 타이머 실행 중 10초마다 세션 저장 (앱 종료 대비)
                if newElapsed % 10 == 0 {
                    saveActiveSession(elapsedSeconds: newElapsed, startTime: currentState.timerStartDate ?? Date())
                }
            }

            return .concat(mutations)

        case .enterBackground:
            // backgroundTime이 nil일 때만 설정 (첫 백그라운드 진입)
            if backgroundTime == nil {
                backgroundTime = Date()
                print("[ReadingTimer] 📱 Entering background (first time) - saving session immediately")
            } else {
                print("[ReadingTimer] 📱 Re-entering background - updating session")
            }

            // 백그라운드 진입 시 즉시 저장하여 오차 최소화
            saveActiveSession(
                elapsedSeconds: currentState.elapsedSeconds,
                startTime: currentState.timerStartDate ?? Date(),
                pausedDuration: currentState.pausedDuration,
                pauseStartTime: currentState.pauseStartTime,
                state: currentState.timerState == .running ? "running" : "paused"
            )
            return .empty()

        case .enterForeground:
            return handleForeground()

        case .setSession(let session):
            return .just(.setSession(session))

        case .checkDuplicateSession:
            if let activeSession = timerSessionManager.getActiveSession() {
                print("[ReadingTimer] Found duplicate session: \(activeSession.bookTitle)")
                return .just(.setDuplicateSessionInfo(activeSession))
            }
            return .empty()

        case .terminateExistingSessionAndStart:
            // 기존 세션 강제 종료
            timerSessionManager.clearActiveSession()
            // 라이브 액티비티도 종료
            if #available(iOS 16.2, *) {
                _ = LiveActivityManager.shared.endActivity()
            }
            // 새로운 타이머 시작
            return validateAndRequestPermissions()

        case .setElapsedSeconds(let seconds):
            return .just(.setElapsedSeconds(seconds))

        case .setRemainingSeconds(let seconds):
            return .just(.setRemainingSeconds(seconds))
        }
    }

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

        case .setTimerStartDate(let date):
            newState.timerStartDate = date

        case .setPausedDuration(let duration):
            newState.pausedDuration = duration

        case .setPauseStartTime(let date):
            newState.pauseStartTime = date

        case .setDuplicateSessionInfo(let info):
            newState.duplicateSessionInfo = info

        case .setError:
            break
        }

        return newState
    }

    // MARK: - Private Methods

    private func createSession() -> Observable<Mutation> {
        // sessionId를 사용하여 세션 생성
        let session = RealmReadingSession(
            id: sessionId,
            bookId: currentState.bookId,
            startTime: currentState.timerStartDate ?? Date(),
            targetMinutes: currentState.targetMinutes,
            status: .inProgress
        )

        print("[ReadingTimer] 💾 Creating new RealmSession with id: \(sessionId)")

        return sessionRepository.saveSession(session)
            .map { savedSession in
                print("[ReadingTimer] ✅ RealmSession created successfully: \(savedSession.id)")
                return .setSession(savedSession)
            }
            .catch { error in
                print("[ReadingTimer] ❌ Failed to create RealmSession: \(error)")
                return .just(.setError(error))
            }
    }

    private func completeSession() -> Observable<Mutation> {
        guard let session = currentState.session else {
            return .just(.setTimerState(.completed))
        }

        // 최소 기록 시간 검증 (1분 = 60초)
        let minimumSeconds = 58
        
        if currentState.elapsedSeconds < minimumSeconds {
            print("[ReadingTimer] ⚠️ Session too short: \(currentState.elapsedSeconds)s (minimum: \(minimumSeconds)s)")
            return .just(.setValidationError(.sessionTooShort))
        }

        let drawingData = generateDrawingData()

        return sessionRepository.completeSession(
            sessionId: session.id,
            endTime: Date(),
            drawingData: drawingData
        )
        .map { _ in .setTimerState(.completed) }
        .catch { error in
            return .concat([
                .just(.setError(error)),
                .just(.setTimerState(.completed))
            ])
        }
    }

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

    private func handleForeground() -> Observable<Mutation> {
        print("[ReadingTimer] 🔄 Returning from background")
        print("  - backgroundTime: \(backgroundTime?.description ?? "nil")")
        print("  - currentState.timerState: \(currentState.timerState)")
        print("  - currentState.elapsedSeconds: \(currentState.elapsedSeconds)")

        guard let backgroundTime = backgroundTime else {
            print("[ReadingTimer] No background time recorded")
            return .empty()
        }

        // 타이머가 이미 완료되었으면 Live Activity만 종료
        if currentState.timerState == .completed {
            self.backgroundTime = nil
            print("[ReadingTimer] Timer already completed in background - ending Live Activity")
            endLiveActivity()
            return .empty()
        }

        let elapsed = Int(Date().timeIntervalSince(backgroundTime))
        let targetSeconds = currentState.targetMinutes * 60
        let newElapsed = min(currentState.elapsedSeconds + elapsed, targetSeconds)
        let newRemaining = max(0, targetSeconds - newElapsed)

        print("[ReadingTimer] Calculating foreground state:")
        print("  - elapsed in background: \(elapsed)s")
        print("  - newElapsed: \(newElapsed)s")
        print("  - newRemaining: \(newRemaining)s")

        self.backgroundTime = nil

        var mutations: [Observable<Mutation>] = [
            .just(.setElapsedSeconds(newElapsed)),
            .just(.setRemainingSeconds(newRemaining))
        ]

        // 백그라운드에서 타이머가 완료되었는지 확인
        if newRemaining == 0 {
            print("[ReadingTimer] 🏁 Timer completed in background!")
            stopTimerTick()
            cancelNotification()
            endLiveActivity()
            clearActiveSession()
            mutations.append(completeSession())
        } else if currentState.timerState == .running {
            print("[ReadingTimer] ▶️ Resuming timer from background")
            // 타이머가 실행 중이었다면 앱 내 타이머만 재시작
            // 라이브 액티비티는 백그라운드에서도 계속 실행 중이므로 업데이트 불필요
            startTimerTick()
            scheduleNotification()
            saveActiveSession(
                elapsedSeconds: newElapsed,
                startTime: currentState.timerStartDate ?? Date(),
                pausedDuration: currentState.pausedDuration,
                state: "running"
            )
        }

        return .concat(mutations)
    }

    private func generateDrawingData() -> DrawingData {
        let seed = Int.random(in: 0...Int.max)

        // Simple organic path generator
        let element = DrawingElement(
            type: .organicPath,
            commands: generateOrganicPath(seed: seed),
            style: DrawingStyle(
                strokeColor: "#2C5F2D",
                strokeWidth: 2.0,
                fillColor: nil,
                opacity: 0.8
            ),
            timing: AnimationTiming(
                delay: 0.0,
                duration: 2.5,
                easing: "easeInOut"
            )
        )

        return DrawingData(
            generatorType: "organic_v1",
            seed: seed,
            instructions: [element]
        )
    }

    private func generateOrganicPath(seed: Int) -> [DrawingCommand] {
        var generator = SeededRandomGenerator(seed: seed)
        var commands: [DrawingCommand] = []

        // Start point
        let startX = generator.nextDouble(in: 0.2...0.3)
        let startY = generator.nextDouble(in: 0.4...0.6)
        commands.append(DrawingCommand(
            type: .move,
            points: [Point(x: startX, y: startY)],
            controlPoints: nil
        ))

        // Generate 3-5 smooth curves
        let curveCount = generator.nextInt(in: 3...5)
        var currentX = startX
        var currentY = startY

        for _ in 0..<curveCount {
            let endX = min(1.0, currentX + generator.nextDouble(in: 0.1...0.3))
            let endY = generator.nextDouble(in: 0.2...0.8)

            let cp1X = currentX + generator.nextDouble(in: 0.05...0.15)
            let cp1Y = currentY + generator.nextDouble(in: -0.2...0.2)
            let cp2X = endX - generator.nextDouble(in: 0.05...0.15)
            let cp2Y = endY + generator.nextDouble(in: -0.2...0.2)

            commands.append(DrawingCommand(
                type: .curve,
                points: [Point(x: endX, y: endY)],
                controlPoints: [
                    Point(x: cp1X, y: cp1Y),
                    Point(x: cp2X, y: cp2Y)
                ]
            ))

            currentX = endX
            currentY = endY
        }

        return commands
    }

    // MARK: - Validation

    private func validateAndRequestPermissions() -> Observable<Mutation> {
        // 1. 중복 세션 체크
        if timerSessionManager.hasActiveSession() {
            print("[ReadingTimer] ⚠️ Active session already exists")
            // TODO: 중복 세션 처리 다이얼로그 표시
            return .empty()
        }

        // 2. 알림 권한 체크
        return notificationManager.checkAuthorizationStatus()
            .flatMap { [weak self] notificationStatus -> Observable<(UNAuthorizationStatus, Bool)> in
                guard let self = self else { return .empty() }

                // 3. 라이브 액티비티 권한 체크
                if #available(iOS 16.2, *) {
                    return LiveActivityManager.shared.checkActivityAuthorizationStatus()
                        .map { liveActivityEnabled in
                            (notificationStatus, liveActivityEnabled)
                        }
                } else {
                    return .just((notificationStatus, false))
                }
            }
            .flatMap { [weak self] (notificationStatus, liveActivityEnabled) -> Observable<Mutation> in
                guard let self = self else { return .empty() }

                // 알림 권한 처리
                let notificationPermission: Observable<Mutation>
                switch notificationStatus {
                case .notDetermined:
                    notificationPermission = self.notificationManager.requestAuthorization()
                        .flatMap { granted -> Observable<Mutation> in
                            if granted {
                                self.scheduleNotificationWithoutPermissionCheck()
                                return .just(.clearValidationError)
                            } else {
                                return .just(.setValidationError(.notificationPermissionDenied))
                            }
                        }

                case .authorized, .provisional:
                    self.scheduleNotificationWithoutPermissionCheck()
                    notificationPermission = .just(.clearValidationError)

                case .denied, .ephemeral:
                    notificationPermission = .just(.setValidationError(.notificationPermissionDenied))

                @unknown default:
                    notificationPermission = .just(.setValidationError(.notificationPermissionDenied))
                }

                // 라이브 액티비티 권한 처리
                if !liveActivityEnabled {
                    print("[ReadingTimer] ⚠️ Live Activity not enabled")
                    return Observable.concat([
                        notificationPermission,
                        .just(.setValidationError(.liveActivityNotEnabled))
                    ])
                }

                return Observable.concat([
                    notificationPermission,
                    .just(.setTimerState(.running))
                ])
            }
            .flatMap { [weak self] mutation -> Observable<Mutation> in
                guard let self = self else { return .just(mutation) }

                // 타이머 시작 mutation이면 실제로 타이머 시작
                if case .setTimerState(.running) = mutation {
                    let startTime = Date()
                    self.saveActiveSession(elapsedSeconds: 0, startTime: startTime)
                    self.startTimerTick()
                    self.startLiveActivity()
                    return .concat([
                        .just(.setTimerStartDate(startTime)),
                        .just(mutation)
                    ])
                }

                return .just(mutation)
            }
    }

    // MARK: - Notification Management

    private func scheduleNotification() {
        // Resume할 때 알림 재스케줄
        scheduleNotificationWithoutPermissionCheck()
    }

    private func scheduleNotificationWithoutPermissionCheck() {
        guard !notificationScheduled, currentState.remainingSeconds > 0 else { return }

        // 메인 스레드에서 Realm 객체 속성 추출
        Observable.just(())
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }

                let remainingSeconds = TimeInterval(self.currentState.remainingSeconds)

                // Realm 객체의 속성을 메인 스레드에서 추출
                guard let session = self.currentState.session else {
                    print("[ReadingTimer] ⚠️ No session available for notification")
                    return
                }

                let sessionId = session.id
                let bookTitle = self.currentState.bookTitle

                // 이제 안전하게 백그라운드에서 사용 가능
                self.notificationManager.scheduleTimerCompletionNotification(
                    afterSeconds: remainingSeconds,
                    sessionId: sessionId,
                    bookTitle: bookTitle
                )
                .subscribe(onNext: { [weak self] notificationId in
                    self?.scheduledNotificationId = notificationId
                    self?.notificationScheduled = true
                    print("[ReadingTimer] 🔔 Notification scheduled with ID: \(notificationId)")
                })
                .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    private func cancelNotification() {
        // 새 시스템으로 취소
        if let notificationId = scheduledNotificationId {
            notificationManager.cancelNotification(withIdentifier: notificationId)
                .subscribe(onNext: { [weak self] in
                    self?.scheduledNotificationId = nil
                    self?.notificationScheduled = false
                    print("[ReadingTimer] 🔕 Notification cancelled")
                })
                .disposed(by: disposeBag)
        } else {
            // 레거시 호환
            notificationManager.cancelTimerCompletionNotification()
            notificationScheduled = false
        }
    }

    // MARK: - Live Activity Management

    private func startLiveActivity() {
        guard #available(iOS 16.2, *) else {
            print("[ReadingTimer] iOS 16.2+ required for Live Activity")
            return
        }

        guard !liveActivityStarted else {
            print("[ReadingTimer] Live Activity already started")
            return
        }

        print("[ReadingTimer] Starting Live Activity - bookTitle: \(currentState.bookTitle), targetMinutes: \(currentState.targetMinutes)")

        // Live Activity 시작
        LiveActivityManager.shared.startActivity(
            bookTitle: currentState.bookTitle,
            targetMinutes: currentState.targetMinutes
        )
        .subscribe(
            onNext: { [weak self] in
                print("[ReadingTimer] ✅ Live Activity started successfully")
                self?.liveActivityStarted = true
            },
            onError: { error in
                print("[ReadingTimer] ❌ Failed to start Live Activity: \(error)")
            }
        )
        .disposed(by: disposeBag)

        // 사용자가 Live Activity를 닫았을 때 처리
        LiveActivityManager.shared.activityDismissed
            .take(1)
            .subscribe(onNext: { [weak self] in
                print("[ReadingTimer] 🗑️ User dismissed Live Activity - resetting flag")
                self?.liveActivityStarted = false
            })
            .disposed(by: disposeBag)
    }

    private func updateLiveActivityPaused() {
        guard #available(iOS 16.2, *), liveActivityStarted else {
            print("[ReadingTimer] Cannot update paused - liveActivityStarted: \(liveActivityStarted)")
            return
        }

        print("[ReadingTimer] Updating Live Activity to PAUSED - elapsed: \(currentState.elapsedSeconds)s")
        LiveActivityManager.shared.updateActivity(
            elapsedSeconds: currentState.elapsedSeconds,
            isPaused: true,
            targetSeconds: currentState.targetMinutes * 60
        )
        .subscribe(
            onError: { error in
                print("[ReadingTimer] ❌ Failed to update (paused): \(error)")
            }
        )
        .disposed(by: disposeBag)
    }

    private func updateLiveActivityResumed() {
        guard #available(iOS 16.2, *), liveActivityStarted else {
            print("[ReadingTimer] Cannot update resumed - liveActivityStarted: \(liveActivityStarted)")
            return
        }

        print("[ReadingTimer] Updating Live Activity to RESUMED - elapsed: \(currentState.elapsedSeconds)s")
        LiveActivityManager.shared.updateActivity(
            elapsedSeconds: currentState.elapsedSeconds,
            isPaused: false,
            targetSeconds: currentState.targetMinutes * 60
        )
        .subscribe(
            onError: { error in
                print("[ReadingTimer] ❌ Failed to update (resumed): \(error)")
            }
        )
        .disposed(by: disposeBag)
    }

    private func endLiveActivity() {
        guard #available(iOS 16.2, *), liveActivityStarted else {
            print("[ReadingTimer] Cannot end - liveActivityStarted: \(liveActivityStarted)")
            return
        }

        print("[ReadingTimer] Ending Live Activity...")
        LiveActivityManager.shared.endActivity()
            .subscribe(
                onNext: { [weak self] in
                    print("[ReadingTimer] ✅ Live Activity ended successfully")
                    self?.liveActivityStarted = false
                },
                onError: { [weak self] error in
                    print("[ReadingTimer] ❌ Failed to end Live Activity: \(error)")
                    self?.liveActivityStarted = false
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - Session Management

    private func saveActiveSession(
        elapsedSeconds: Int,
        startTime: Date,
        pausedDuration: Int = 0,
        pauseStartTime: Date? = nil,
        state: String = "running"
    ) {
        timerSessionManager.saveActiveSession(
            sessionId: sessionId,
            bookId: currentState.bookId,
            bookTitle: currentState.bookTitle,
            targetMinutes: currentState.targetMinutes,
            startTime: startTime,
            elapsedSeconds: elapsedSeconds,
            pausedDuration: pausedDuration,
            pauseStartTime: pauseStartTime,
            state: state,
            activityId: nil  // TODO: 라이브 액티비티 ID 저장
        )
    }

    private func clearActiveSession() {
        timerSessionManager.clearActiveSession()
    }

    // MARK: - Activity State Monitoring

    private func setupActivityStateMonitoring() {
        guard #available(iOS 16.2, *) else { return }

        // Stale 상태 모니터링 (8시간 제한)
        LiveActivityManager.shared.activityStale
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                print("[ReadingTimer] ⏰ Live Activity became stale - recreating...")

                // 기존 액티비티 종료
                self.endLiveActivity()

                // 새 액티비티 시작 (현재 경과 시간 유지)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startLiveActivity()
                }
            })
            .disposed(by: disposeBag)

        // 사용자가 닫은 경우
        LiveActivityManager.shared.activityDismissed
            .subscribe(onNext: { [weak self] in
                print("[ReadingTimer] 🗑️ User dismissed Live Activity")
                self?.liveActivityStarted = false
            })
            .disposed(by: disposeBag)

        // 액티비티 종료
        LiveActivityManager.shared.activityEnded
            .subscribe(onNext: { [weak self] in
                print("[ReadingTimer] ⏹️ Live Activity ended")
                self?.liveActivityStarted = false
            })
            .disposed(by: disposeBag)
    }

    deinit {
        stopTimerTick()
        cancelNotification()
        endLiveActivity()
    }
}

// MARK: - Seeded Random Generator

struct SeededRandomGenerator {
    private var state: UInt64

    init(seed: Int) {
        self.state = UInt64(seed)
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }

    mutating func nextDouble(in range: ClosedRange<Double> = 0...1) -> Double {
        let random = Double(next()) / Double(UInt64.max)
        return range.lowerBound + (random * (range.upperBound - range.lowerBound))
    }

    mutating func nextInt(in range: ClosedRange<Int>) -> Int {
        let random = Int(next() % UInt64(range.upperBound - range.lowerBound + 1))
        return range.lowerBound + random
    }
}
