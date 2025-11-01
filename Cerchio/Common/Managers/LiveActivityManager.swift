//
//  LiveActivityManager.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import ActivityKit
import RxSwift

@available(iOS 16.2, *)
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private init() {}

    private var currentActivity: Activity<ReadingTimerAttributes>?
    private var activityStateObserver: Task<Void, Never>?
    private let activityDismissedSubject = PublishSubject<Void>()
    private let activityStaleSubject = PublishSubject<Void>()
    private let activityEndedSubject = PublishSubject<Void>()
    
    var activityDismissed: Observable<Void> {
        activityDismissedSubject.asObservable()
    }
    
    var activityStale: Observable<Void> {
        activityStaleSubject.asObservable()
    }
    
    var activityEnded: Observable<Void> {
        activityEndedSubject.asObservable()
    }
    
    func checkActivityAuthorizationStatus() -> Observable<Bool> {
        return Observable.create { observer in
            let authInfo = ActivityAuthorizationInfo()
            let isEnabled = authInfo.areActivitiesEnabled
            
            observer.onNext(isEnabled)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func getActiveActivities() -> [Activity<ReadingTimerAttributes>] {
        return Activity<ReadingTimerAttributes>.activities
    }

    func restoreActivity(_ activity: Activity<ReadingTimerAttributes>) {
        currentActivity = activity
        observeActivityState(activity)
    }
    
    func startActivity(
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date,
        targetEndTime: Date
    ) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            let authInfo = ActivityAuthorizationInfo()
            
            guard authInfo.areActivitiesEnabled else {
                observer.onError(LiveActivityError.notEnabled)
                return Disposables.create()
            }

            do {
                let attributes = ReadingTimerAttributes(
                    bookTitle: bookTitle,
                    sessionStartTime: sessionStartTime
                )

                let targetSeconds = targetMinutes * 60
                let initialState = ReadingTimerAttributes.ContentState(
                    timerStartTime: Date(),
                    pausedElapsedSeconds: 0,
                    targetSeconds: targetSeconds,
                    isPaused: false,
                    isCompleted: false,
                    lastUpdateTime: Date()
                )
                
                let content = ActivityContent(
                    state: initialState,
                    staleDate: targetEndTime,
                    relevanceScore: 1.0
                )

                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                
                self?.currentActivity = activity
                self?.observeActivityState(activity)

                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
    
    @MainActor
    func updateActivity(
        timerStartTime: Date?,
        pausedElapsedSeconds: Int,
        targetSeconds: Int,
        isPaused: Bool
    ) async throws {
        guard let activity = currentActivity else {
            throw LiveActivityError.noActiveActivity
        }

        let newState = ReadingTimerAttributes.ContentState(
            timerStartTime: timerStartTime,
            pausedElapsedSeconds: pausedElapsedSeconds,
            targetSeconds: targetSeconds,
            isPaused: isPaused,
            isCompleted: false,
            lastUpdateTime: Date()
        )

        let staleDate = timerStartTime?.addingTimeInterval(TimeInterval(targetSeconds - pausedElapsedSeconds))

        await activity.update(.init(state: newState, staleDate: staleDate))
    }
    
    func endAllActivities() -> Observable<Void> {
        return Observable.create { observer in
            let activities = Activity<ReadingTimerAttributes>.activities

            guard !activities.isEmpty else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }
            
            Task {
                for activity in activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }

                observer.onNext(())
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    func endActivity(immediate: Bool = false) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let activity = self?.currentActivity else {
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }

            Task {
                if immediate {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    let completedState = ReadingTimerAttributes.ContentState(
                        timerStartTime: nil,
                        pausedElapsedSeconds: activity.content.state.targetSeconds,
                        targetSeconds: activity.content.state.targetSeconds,
                        isPaused: false,
                        isCompleted: true,
                        lastUpdateTime: Date()
                    )
                    
                    await activity.end(
                        .init(state: completedState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                }
                
                self?.cleanupActivity()
                observer.onNext(())
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    private func observeActivityState(_ activity: Activity<ReadingTimerAttributes>) {
        activityStateObserver?.cancel()
        
        activityStateObserver = Task {
            for await state in activity.activityStateUpdates {
                switch state {
                case .dismissed:
                    self.activityDismissedSubject.onNext(())
                    self.cleanupActivity()

                case .ended:
                    self.activityEndedSubject.onNext(())
                    self.cleanupActivity()

                case .stale:
                    self.activityStaleSubject.onNext(())

                case .active:
                    break

                case .pending:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func cleanupActivity() {
        activityStateObserver?.cancel()
        activityStateObserver = nil
        currentActivity = nil
    }

    enum LiveActivityError: Error {
        case notEnabled
        case noActiveActivity
    }
}
