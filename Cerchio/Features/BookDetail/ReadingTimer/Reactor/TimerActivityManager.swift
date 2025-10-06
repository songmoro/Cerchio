//
//  TimerActivityManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import RxRelay

/// Live Activity 관리 전담 클래스
final class TimerActivityManager {

    // MARK: - Properties

    @available(iOS 16.2, *)
    private var liveActivityManager: LiveActivityManager { LiveActivityManager.shared }
    private var isStarted = false
    private let disposeBag = DisposeBag()

    // Event relays
    private let dismissedRelay = PublishRelay<Void>()
    private let staleRelay = PublishRelay<Void>()
    private let endedRelay = PublishRelay<Void>()

    var activityDismissed: Observable<Void> { dismissedRelay.asObservable() }
    var activityStale: Observable<Void> { staleRelay.asObservable() }
    var activityEnded: Observable<Void> { endedRelay.asObservable() }

    // MARK: - Initialization

    init() {
        if #available(iOS 16.2, *) {
            setupMonitoring()
        }
    }

    // MARK: - Start/Stop

    @available(iOS 16.2, *)
    func start(
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date,
        targetEndTime: Date
    ) -> Observable<Void> {
        guard !isStarted else {
            print("[TimerActivity] ⚠️ Already started")
            return .just(())
        }

        print("[TimerActivity] 🚀 Starting Live Activity")
        print("  - bookTitle: \(bookTitle)")
        print("  - targetMinutes: \(targetMinutes)")
        print("  - targetEndTime: \(targetEndTime)")

        return liveActivityManager.startActivity(
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime,
            targetEndTime: targetEndTime
        )
        .do(onNext: { [weak self] in
            self?.isStarted = true
            print("[TimerActivity] ✅ Started successfully")
        }, onError: { error in
            print("[TimerActivity] ❌ Failed to start: \(error)")
        })
    }

    @available(iOS 16.2, *)
    func end() -> Observable<Void> {
        guard isStarted else {
            print("[TimerActivity] ⚠️ Not started")
            return .just(())
        }

        print("[TimerActivity] 🛑 Ending Live Activity")
        return liveActivityManager.endActivity()
            .do(onNext: { [weak self] in
                self?.isStarted = false
                print("[TimerActivity] ✅ Ended successfully")
            }, onError: { [weak self] error in
                self?.isStarted = false
                print("[TimerActivity] ❌ Failed to end: \(error)")
            })
    }

    // MARK: - Update

    @available(iOS 16.2, *)
    func update(
        targetEndTime: Date,
        pausedAt: Date?,
        targetSeconds: Int
    ) -> Observable<Void> {
        guard isStarted else {
            print("[TimerActivity] ⚠️ Cannot update (not started)")
            return .just(())
        }

        let isPaused = pausedAt != nil
        print("[TimerActivity] \(isPaused ? "⏸️ PAUSED" : "▶️ RESUMED")")
        print("  - targetEndTime: \(targetEndTime)")
        print("  - pausedAt: \(pausedAt?.description ?? "nil")")

        // targetEndTime 기반에서 timerStartTime 기반으로 변환
        let timerStartTime: Date?
        let pausedElapsedSeconds: Int

        if let pausedTime = pausedAt {
            // 일시정지 상태
            timerStartTime = nil
            let remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
            pausedElapsedSeconds = targetSeconds - remaining
        } else {
            // 실행 중
            let remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
            pausedElapsedSeconds = targetSeconds - remaining

            // timerStartTime = 현재 - 이미 경과한 시간
            timerStartTime = Date().addingTimeInterval(-TimeInterval(pausedElapsedSeconds))
        }

        return liveActivityManager.updateActivity(
            timerStartTime: timerStartTime,
            pausedElapsedSeconds: pausedElapsedSeconds,
            targetSeconds: targetSeconds,
            isPaused: isPaused
        )
        .catch { error -> Observable<Void> in
            print("[TimerActivity] ❌ Update failed: \(error)")
            return .just(())
        }
    }

    @available(iOS 16.2, *)
    func restart(
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date,
        targetEndTime: Date,
        pausedAt: Date?,
        targetSeconds: Int
    ) -> Observable<Void> {
        print("[TimerActivity] 🔄 Restarting Live Activity")

        return start(
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime,
            targetEndTime: targetEndTime
        )
        .flatMap { [weak self] _ -> Observable<Void> in
            guard let self = self else { return .empty() }

            print("[TimerActivity] ✅ Restarted - updating state...")

            // targetEndTime 기반에서 timerStartTime 기반으로 변환
            let timerStartTime: Date?
            let pausedElapsedSeconds: Int
            let isPaused = pausedAt != nil

            if let pausedTime = pausedAt {
                // 일시정지 상태
                timerStartTime = nil
                let remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
                pausedElapsedSeconds = targetSeconds - remaining
            } else {
                // 실행 중
                let remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
                pausedElapsedSeconds = targetSeconds - remaining
                timerStartTime = Date().addingTimeInterval(-TimeInterval(pausedElapsedSeconds))
            }

            return self.liveActivityManager.updateActivity(
                timerStartTime: timerStartTime,
                pausedElapsedSeconds: pausedElapsedSeconds,
                targetSeconds: targetSeconds,
                isPaused: isPaused
            )
        }
        .do(onNext: {
            print("[TimerActivity] ✅ Restarted and synced")
        }, onError: { error in
            print("[TimerActivity] ❌ Restart failed: \(error)")
        })
    }

    @available(iOS 16.2, *)
    func syncOnRestore(
        targetEndTime: Date,
        pausedAt: Date?,
        targetSeconds: Int,
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<Void> {
        let activeActivities = liveActivityManager.getActiveActivities()

        if activeActivities.isEmpty {
            print("[TimerActivity] 📱 No active activity - creating new one")

            return start(
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionStartTime: sessionStartTime,
                targetEndTime: targetEndTime
            )
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }

                // targetEndTime 기반에서 timerStartTime 기반으로 변환
                let timerStartTime: Date?
                let pausedElapsedSeconds: Int
                let isPaused = pausedAt != nil

                if let pausedTime = pausedAt {
                    timerStartTime = nil
                    let remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
                    pausedElapsedSeconds = targetSeconds - remaining
                } else {
                    let remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
                    pausedElapsedSeconds = targetSeconds - remaining
                    timerStartTime = Date().addingTimeInterval(-TimeInterval(pausedElapsedSeconds))
                }

                return self.liveActivityManager.updateActivity(
                    timerStartTime: timerStartTime,
                    pausedElapsedSeconds: pausedElapsedSeconds,
                    targetSeconds: targetSeconds,
                    isPaused: isPaused
                )
            }
        }

        print("[TimerActivity] 🔄 Syncing existing activity")

        // targetEndTime 기반에서 timerStartTime 기반으로 변환
        let timerStartTime: Date?
        let pausedElapsedSeconds: Int
        let isPaused = pausedAt != nil

        if let pausedTime = pausedAt {
            timerStartTime = nil
            let remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
            pausedElapsedSeconds = targetSeconds - remaining
        } else {
            let remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
            pausedElapsedSeconds = targetSeconds - remaining
            timerStartTime = Date().addingTimeInterval(-TimeInterval(pausedElapsedSeconds))
        }

        return liveActivityManager.updateActivity(
            timerStartTime: timerStartTime,
            pausedElapsedSeconds: pausedElapsedSeconds,
            targetSeconds: targetSeconds,
            isPaused: isPaused
        )
        .do(onNext: { [weak self] in
            self?.isStarted = true
            print("[TimerActivity] ✅ Synced successfully")
        })
    }

    // MARK: - Monitoring

    @available(iOS 16.2, *)
    private func setupMonitoring() {
        guard #available(iOS 16.2, *) else { return }

        // Dismissed
        liveActivityManager.activityDismissed
            .subscribe(onNext: { [weak self] in
                self?.isStarted = false
                self?.dismissedRelay.accept(())
                print("[TimerActivity] 🗑️ User dismissed activity")
            })
            .disposed(by: disposeBag)

        // Stale (8시간 제한)
        liveActivityManager.activityStale
            .subscribe(onNext: { [weak self] in
                self?.staleRelay.accept(())
                print("[TimerActivity] ⏰ Activity became stale")
            })
            .disposed(by: disposeBag)

        // Ended
        liveActivityManager.activityEnded
            .subscribe(onNext: { [weak self] in
                self?.isStarted = false
                self?.endedRelay.accept(())
                print("[TimerActivity] ⏹️ Activity ended")
            })
            .disposed(by: disposeBag)
    }

    // MARK: - State

    var hasActiveActivity: Bool {
        isStarted
    }
}
