//
//  ReadingTimerReactor.swift
//  Cerchio
//
//  Created by Claude on 10/3/25.
//

import Foundation
import ReactorKit
import RxSwift
import RxCocoa

final class ReadingTimerReactor: Reactor {

    enum Action {
        case viewDidLoad
        case startTimer
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
        case setError(Error)
    }

    struct State {
        var session: RealmReadingSession?
        var timerState: TimerState = .idle
        var elapsedSeconds: Int = 0
        var remainingSeconds: Int = 0
        var targetMinutes: Int = 25
        var bookId: String

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
    private let disposeBag = DisposeBag()

    // Timer management
    private var timerDisposable: Disposable?
    private var backgroundTime: Date?

    init(bookId: String, targetMinutes: Int, sessionRepository: ReadingSessionRepositoryProtocol) {
        self.sessionRepository = sessionRepository
        self.initialState = State(
            remainingSeconds: targetMinutes * 60,
            targetMinutes: targetMinutes,
            bookId: bookId
        )
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return createSession()

        case .startTimer:
            startTimerTick()
            return .just(.setTimerState(.running))

        case .pauseTimer:
            stopTimerTick()
            return .just(.setTimerState(.paused))

        case .resumeTimer:
            startTimerTick()
            return .just(.setTimerState(.running))

        case .stopTimer:
            stopTimerTick()
            return completeSession()

        case .timerTick:
            let targetSeconds = currentState.targetMinutes * 60
            let newElapsed = min(currentState.elapsedSeconds + 1, targetSeconds)
            let newRemaining = max(0, targetSeconds - newElapsed)

            var mutations: [Observable<Mutation>] = [
                .just(.setElapsedSeconds(newElapsed)),
                .just(.setRemainingSeconds(newRemaining))
            ]

            // Check if timer completed
            if newRemaining == 0 {
                stopTimerTick()
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
            mutations.append(completeSession())
        } else if currentState.timerState == .running {
            // 타이머가 실행 중이었다면 재시작
            startTimerTick()
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

    deinit {
        stopTimerTick()
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
