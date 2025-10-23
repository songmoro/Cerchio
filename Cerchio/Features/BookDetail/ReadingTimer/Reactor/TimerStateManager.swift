//
//  TimerStateManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import RxCocoa

final class TimerStateManager {

    enum TimerState {
        case idle
        case running
        case paused
        case completed
    }

    private let stateRelay = BehaviorRelay<TimerState>(value: .idle)
    private let targetEndTimeRelay = BehaviorRelay<Date?>(value: nil)
    private let pausedAtRelay = BehaviorRelay<Date?>(value: nil)

    var state: Observable<TimerState> { stateRelay.asObservable() }
    var targetEndTime: Observable<Date?> { targetEndTimeRelay.asObservable() }
    var pausedAt: Observable<Date?> { pausedAtRelay.asObservable() }

    var currentState: TimerState { stateRelay.value }
    var currentTargetEndTime: Date? { targetEndTimeRelay.value }
    var currentPausedAt: Date? { pausedAtRelay.value }

    private let targetMinutes: Int
    var targetSeconds: Int { targetMinutes * 60 }

    init(targetMinutes: Int, initialState: TimerState = .idle) {
        self.targetMinutes = targetMinutes
        stateRelay.accept(initialState)
    }

    func setState(_ state: TimerState) {
        stateRelay.accept(state)
    }

    func setTargetEndTime(_ endTime: Date?) {
        targetEndTimeRelay.accept(endTime)
    }

    func setPausedAt(_ time: Date?) {
        pausedAtRelay.accept(time)
    }

    var currentElapsedSeconds: Int {
        guard let endTime = currentTargetEndTime else { return 0 }

        if currentState == .paused, let pausedTime = currentPausedAt {
            let remaining = max(0, endTime.timeIntervalSince(pausedTime))
            return targetSeconds - Int(remaining)
        }

        let remaining = max(0, endTime.timeIntervalSince(Date()))
        return targetSeconds - Int(remaining)
    }

    var currentRemainingSeconds: Int {
        guard let endTime = currentTargetEndTime else { return targetSeconds }

        if currentState == .paused, let pausedTime = currentPausedAt {
            return max(0, Int(endTime.timeIntervalSince(pausedTime)))
        }

        return max(0, Int(endTime.timeIntervalSince(Date())))
    }

    func isTimerCompleted() -> Bool {
        guard let endTime = currentTargetEndTime else { return false }
        return Date() >= endTime
    }

    var elapsedTimeString: String {
        formatTime(currentElapsedSeconds)
    }

    var remainingTimeString: String {
        formatTime(currentRemainingSeconds)
    }

    var progress: Double {
        targetSeconds > 0 ? Double(currentElapsedSeconds) / Double(targetSeconds) : 0
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    func isCompleted() -> Bool {
        isTimerCompleted() || currentState == .completed
    }

    func canSaveSession(minimumSeconds: Int = 58) -> Bool {
        currentElapsedSeconds >= minimumSeconds
    }
}
