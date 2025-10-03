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
    }

    enum Mutation {
        case setSession(RealmReadingSession)
        case setTimerState(TimerState)
        case setElapsedSeconds(Int)
        case setRemainingSeconds(Int)
        case setValidationError(ValidationError)
        case clearValidationError
        case setError(Error)
    }

    enum ValidationError: Error, Equatable {
        case notificationPermissionDenied
        case liveActivityNotEnabled
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
    private let disposeBag = DisposeBag()

    // Timer management
    private var timerDisposable: Disposable?
    private var backgroundTime: Date?
    private var notificationScheduled = false
    private var liveActivityStarted = false

    init(bookId: String, bookTitle: String, targetMinutes: Int, sessionRepository: ReadingSessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.initialState = State(
            remainingSeconds: targetMinutes * 60,
            targetMinutes: targetMinutes,
            bookId: bookId,
            bookTitle: bookTitle
        )
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return createSession()

        case .requestTimerStart:
            return validateAndRequestPermissions()

        case .startTimerConfirmed:
            startTimerTick()
            startLiveActivity()
            return .just(.setTimerState(.running))

        case .pauseTimer:
            stopTimerTick()
            cancelNotification()
            updateLiveActivityPaused()
            return .just(.setTimerState(.paused))

        case .resumeTimer:
            startTimerTick()
            scheduleNotification()
            updateLiveActivityResumed()
            return .just(.setTimerState(.running))

        case .stopTimer:
            stopTimerTick()
            cancelNotification()
            endLiveActivity()
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
                updateLiveActivityCompleted()
                mutations.append(completeSession())
            }

            return .concat(mutations)

        case .enterBackground:
            backgroundTime = Date()
            return .empty()

        case .enterForeground:
            return handleForeground()
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

        case .setError:
            break
        }

        return newState
    }

    // MARK: - Private Methods

    private func createSession() -> Observable<Mutation> {
        let session = RealmReadingSession(
            bookId: currentState.bookId,
            startTime: Date(),
            targetMinutes: currentState.targetMinutes,
            status: .inProgress
        )

        return sessionRepository.saveSession(session)
            .map { .setSession($0) }
            .catch { error in
                return .just(.setError(error))
            }
    }

    private func completeSession() -> Observable<Mutation> {
        guard let session = currentState.session else {
            return .just(.setTimerState(.completed))
        }

        // TODO: Generate drawing data here
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
        guard let backgroundTime = backgroundTime else {
            return .empty()
        }

        // 타이머가 이미 완료되었으면 아무것도 하지 않음
        if currentState.timerState == .completed {
            self.backgroundTime = nil
            return .empty()
        }

        let elapsed = Int(Date().timeIntervalSince(backgroundTime))
        let targetSeconds = currentState.targetMinutes * 60
        let newElapsed = min(currentState.elapsedSeconds + elapsed, targetSeconds)
        let newRemaining = max(0, targetSeconds - newElapsed)

        self.backgroundTime = nil

        var mutations: [Observable<Mutation>] = [
            .just(.setElapsedSeconds(newElapsed)),
            .just(.setRemainingSeconds(newRemaining))
        ]

        // 백그라운드에서 타이머가 완료되었는지 확인
        if newRemaining == 0 {
            stopTimerTick()
            cancelNotification()
            updateLiveActivityCompleted()
            mutations.append(completeSession())
        } else if currentState.timerState == .running {
            // 타이머가 실행 중이었다면 재시작
            startTimerTick()
            scheduleNotification()
            updateLiveActivityResumed()
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
        return notificationManager.checkAuthorizationStatus()
            .flatMap { [weak self] status -> Observable<Mutation> in
                guard let self = self else { return .empty() }

                switch status {
                case .notDetermined:
                    // 권한 요청
                    return self.notificationManager.requestAuthorization()
                        .flatMap { granted -> Observable<Mutation> in
                            if granted {
                                // 권한 승인됨 - 알림 스케줄하고 타이머 시작
                                self.scheduleNotificationWithoutPermissionCheck()
                                return .concat([
                                    .just(.clearValidationError),
                                    .just(.setTimerState(.running))
                                ])
                            } else {
                                // 권한 거부됨 - 에러 설정
                                return .just(.setValidationError(.notificationPermissionDenied))
                            }
                        }

                case .authorized, .provisional:
                    // 권한 있음 - 알림 스케줄하고 타이머 시작
                    self.scheduleNotificationWithoutPermissionCheck()
                    return .concat([
                        .just(.clearValidationError),
                        .just(.setTimerState(.running))
                    ])

                case .denied, .ephemeral:
                    // 권한 없음 - 에러 설정
                    return .just(.setValidationError(.notificationPermissionDenied))

                @unknown default:
                    return .just(.setValidationError(.notificationPermissionDenied))
                }
            }
            .flatMap { [weak self] mutation -> Observable<Mutation> in
                guard let self = self else { return .just(mutation) }

                // 타이머 시작 mutation이면 실제로 타이머 시작
                if case .setTimerState(.running) = mutation {
                    self.startTimerTick()
                    self.startLiveActivity()
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

        let remainingSeconds = TimeInterval(currentState.remainingSeconds)
        notificationManager.scheduleTimerCompletionNotification(afterSeconds: remainingSeconds)
            .subscribe(onNext: { [weak self] in
                self?.notificationScheduled = true
            })
            .disposed(by: disposeBag)
    }

    private func cancelNotification() {
        notificationManager.cancelTimerCompletionNotification()
        notificationScheduled = false
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

    private func updateLiveActivityCompleted() {
        guard #available(iOS 16.2, *), liveActivityStarted else { return }

        // 완료 상태로 업데이트 후 종료
        endLiveActivity()
    }

    private func endLiveActivity() {
        guard #available(iOS 16.2, *), liveActivityStarted else { return }

        LiveActivityManager.shared.endActivity()
            .subscribe(onNext: { [weak self] in
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
