//
//  TimerActivityManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import Foundation
import RxSwift
import RxRelay

final class TimerActivityManager {

    @available(iOS 16.2, *)
    private var liveActivityManager: LiveActivityManager { LiveActivityManager.shared }
    private var isStarted = false
    private let disposeBag = DisposeBag()

    private let dismissedRelay = PublishRelay<Void>()
    private let staleRelay = PublishRelay<Void>()
    private let endedRelay = PublishRelay<Void>()

    var activityDismissed: Observable<Void> { dismissedRelay.asObservable() }
    var activityStale: Observable<Void> { staleRelay.asObservable() }
    var activityEnded: Observable<Void> { endedRelay.asObservable() }

    init() {
        if #available(iOS 16.2, *) {
            setupMonitoring()
        }
    }

    @available(iOS 16.2, *)
    func start(
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date,
        targetEndTime: Date
    ) -> Observable<Void> {
        guard !isStarted else {
            return .just(())
        }

        return liveActivityManager.startActivity(
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime,
            targetEndTime: targetEndTime
        )
        .do(onNext: { [weak self] in
            self?.isStarted = true
        })
    }

    @available(iOS 16.2, *)
    func end(immediate: Bool = false) -> Observable<Void> {
        guard isStarted else {
            return .just(())
        }

        return liveActivityManager.endActivity(immediate: immediate)
            .do(onNext: { [weak self] in
                self?.isStarted = false
            }, onError: { [weak self] error in
                self?.isStarted = false
            })
    }

    @available(iOS 16.2, *)
    func update(
        targetEndTime: Date,
        pausedAt: Date?,
        targetSeconds: Int
    ) -> Observable<Void> {
        guard isStarted else {
            return .just(())
        }

        let isPaused = pausedAt != nil

        let timerStartTime: Date?
        let pausedElapsedSeconds: Int

        if let pausedTime = pausedAt {
            timerStartTime = nil
            let remaining = max(0, Int(targetEndTime.timeIntervalSince(pausedTime)))
            pausedElapsedSeconds = targetSeconds - remaining
        } else {
            let remaining = max(0, Int(targetEndTime.timeIntervalSince(Date())))
            pausedElapsedSeconds = targetSeconds - remaining

            timerStartTime = targetEndTime.addingTimeInterval(-TimeInterval(targetSeconds - pausedElapsedSeconds))
        }

        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let task = Task { @MainActor in
                do {
                    try await self.liveActivityManager.updateActivity(
                        timerStartTime: timerStartTime,
                        pausedElapsedSeconds: pausedElapsedSeconds,
                        targetSeconds: targetSeconds,
                        isPaused: isPaused
                    )
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
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

        return start(
            bookTitle: bookTitle,
            targetMinutes: targetMinutes,
            sessionStartTime: sessionStartTime,
            targetEndTime: targetEndTime
        )
        .flatMap { [weak self] _ -> Observable<Void> in
            guard let self = self else { return .empty() }

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
                timerStartTime = targetEndTime.addingTimeInterval(-TimeInterval(targetSeconds - pausedElapsedSeconds))
            }

            return Observable.create { observer in
                let task = Task { @MainActor in
                    do {
                        try await self.liveActivityManager.updateActivity(
                            timerStartTime: timerStartTime,
                            pausedElapsedSeconds: pausedElapsedSeconds,
                            targetSeconds: targetSeconds,
                            isPaused: isPaused
                        )
                        observer.onNext(())
                        observer.onCompleted()
                    } catch {
                        observer.onNext(())
                        observer.onCompleted()
                    }
                }

                return Disposables.create {
                    task.cancel()
                }
            }
        }
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

            return start(
                bookTitle: bookTitle,
                targetMinutes: targetMinutes,
                sessionStartTime: sessionStartTime,
                targetEndTime: targetEndTime
            )
            .flatMap { [weak self] _ -> Observable<Void> in
                guard let self = self else { return .empty() }

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

                return Observable.create { observer in
                    let task = Task { @MainActor in
                        do {
                            try await self.liveActivityManager.updateActivity(
                                timerStartTime: timerStartTime,
                                pausedElapsedSeconds: pausedElapsedSeconds,
                                targetSeconds: targetSeconds,
                                isPaused: isPaused
                            )
                            observer.onNext(())
                            observer.onCompleted()
                        } catch {
                            observer.onNext(())
                            observer.onCompleted()
                        }
                    }

                    return Disposables.create {
                        task.cancel()
                    }
                }
            }
        }

        liveActivityManager.restoreActivity(activeActivities.first!)

        isStarted = true

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
            timerStartTime = targetEndTime.addingTimeInterval(-TimeInterval(targetSeconds - pausedElapsedSeconds))
        }

        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            let task = Task { @MainActor in
                do {
                    try await self.liveActivityManager.updateActivity(
                        timerStartTime: timerStartTime,
                        pausedElapsedSeconds: pausedElapsedSeconds,
                        targetSeconds: targetSeconds,
                        isPaused: isPaused
                    )
                    self.isStarted = true
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    self.isStarted = true
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    @available(iOS 16.2, *)
    private func setupMonitoring() {
        liveActivityManager.activityDismissed
            .subscribe(onNext: { [weak self] in
                self?.isStarted = false
                self?.dismissedRelay.accept(())
            })
            .disposed(by: disposeBag)

        liveActivityManager.activityStale
            .subscribe(onNext: { [weak self] in
                self?.staleRelay.accept(())
            })
            .disposed(by: disposeBag)

        liveActivityManager.activityEnded
            .subscribe(onNext: { [weak self] in
                self?.isStarted = false
                self?.endedRelay.accept(())
            })
            .disposed(by: disposeBag)
    }

    var hasActiveActivity: Bool {
        isStarted
    }
}
