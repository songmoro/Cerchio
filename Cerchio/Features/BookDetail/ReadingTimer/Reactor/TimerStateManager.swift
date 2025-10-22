//
//  TimerStateManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import RxCocoa

/// 타이머의 상태를 관리하는 전담 클래스
final class TimerStateManager {

    // MARK: - Types

    enum TimerState {
        case idle
        case running
        case paused
        case completed
    }

    // MARK: - Properties

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

    // MARK: - Initialization

    init(targetMinutes: Int, initialState: TimerState = .idle) {
        self.targetMinutes = targetMinutes
        stateRelay.accept(initialState)
    }

    // MARK: - State Updates

    func setState(_ state: TimerState) {
        stateRelay.accept(state)
    }

    func setTargetEndTime(_ endTime: Date?) {
        targetEndTimeRelay.accept(endTime)
    }

    func setPausedAt(_ time: Date?) {
        pausedAtRelay.accept(time)
    }

    // MARK: - Time Calculations (종료 시간 기준)

    /// 현재 경과 시간 계산
    var currentElapsedSeconds: Int {
        guard let endTime = currentTargetEndTime else { return 0 }

        if currentState == .paused, let pausedTime = currentPausedAt {
            // 일시정지 상태: 일시정지 시점의 남은 시간 계산
            let remaining = max(0, endTime.timeIntervalSince(pausedTime))
            return targetSeconds - Int(remaining)
        }

        // 실행 중: 현재 남은 시간 계산
        let remaining = max(0, endTime.timeIntervalSince(Date()))
        return targetSeconds - Int(remaining)
    }

    /// 현재 남은 시간 계산
    var currentRemainingSeconds: Int {
        guard let endTime = currentTargetEndTime else { return targetSeconds }

        if currentState == .paused, let pausedTime = currentPausedAt {
            // 일시정지 상태: 일시정지 시점의 남은 시간
            return max(0, Int(endTime.timeIntervalSince(pausedTime)))
        }

        // 실행 중: 현재 남은 시간
        return max(0, Int(endTime.timeIntervalSince(Date())))
    }

    /// 타이머 완료 여부 확인
    func isTimerCompleted() -> Bool {
        guard let endTime = currentTargetEndTime else { return false }
        return Date() >= endTime
    }

    // MARK: - Formatted Strings

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

    // MARK: - Validation

    func isCompleted() -> Bool {
        isTimerCompleted() || currentState == .completed
    }

    func canSaveSession(minimumSeconds: Int = 58) -> Bool {
        currentElapsedSeconds >= minimumSeconds
    }
}
