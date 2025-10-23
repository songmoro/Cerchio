//
//  TimerStopUseCase.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift

final class TimerStopUseCase {

    enum StopError: Error {
        case sessionTooShort(elapsedSeconds: Int, minimumSeconds: Int)
        case noSession
    }

    private let stateManager: TimerStateManager
    private let validationService: TimerValidationService
    private let notificationManager: TimerNotificationManager
    private let activityManager: TimerActivityManager
    private let sessionManager: TimerSessionManager
    private let sessionRepository: ReadingSessionRepositoryProtocol

    init(
        stateManager: TimerStateManager,
        validationService: TimerValidationService,
        notificationManager: TimerNotificationManager,
        activityManager: TimerActivityManager,
        sessionManager: TimerSessionManager,
        sessionRepository: ReadingSessionRepositoryProtocol
    ) {
        self.stateManager = stateManager
        self.validationService = validationService
        self.notificationManager = notificationManager
        self.activityManager = activityManager
        self.sessionManager = sessionManager
        self.sessionRepository = sessionRepository
    }

    func execute(
        sessionId: String,
        realmSession: RealmReadingSession?
    ) -> Observable<Void> {

        let minimumSeconds = 58
        guard validationService.canSaveSession(
            elapsedSeconds: stateManager.currentElapsedSeconds,
            minimumSeconds: minimumSeconds
        ) else {
            return .error(StopError.sessionTooShort(
                elapsedSeconds: stateManager.currentElapsedSeconds,
                minimumSeconds: minimumSeconds
            ))
        }

        guard let session = realmSession else {
            return .error(StopError.noSession)
        }

        _ = notificationManager.cancel().subscribe()

        if #available(iOS 16.2, *) {
            _ = activityManager.end(immediate: false).subscribe()
        }

        sessionManager.clearActiveSession()

        let elapsedSeconds = stateManager.currentElapsedSeconds

        return sessionRepository.completeSession(
            sessionId: session.id,
            endTime: Date(),
            elapsedSeconds: elapsedSeconds,
            drawingData: nil
        )
        .do(onNext: { [weak self] _ in
            self?.stateManager.setState(.completed)
        }, onError: { error in
            print("[TimerStopUseCase]  Failed to complete session: \(error)")
        })
        .map { _ in () }
    }

    private func generateDrawingData() -> DrawingData {
        let seed = Int.random(in: 0...Int.max)

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

        let startX = generator.nextDouble(in: 0.2...0.3)
        let startY = generator.nextDouble(in: 0.4...0.6)
        commands.append(DrawingCommand(
            type: .move,
            points: [Point(x: startX, y: startY)],
            controlPoints: nil
        ))

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
}

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
