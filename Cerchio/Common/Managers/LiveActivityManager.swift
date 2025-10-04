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

    // Activity 상태 변화 알림
    private let activityDismissedSubject = PublishSubject<Void>()
    var activityDismissed: Observable<Void> {
        activityDismissedSubject.asObservable()
    }

    private let activityStaleSubject = PublishSubject<Void>()
    var activityStale: Observable<Void> {
        activityStaleSubject.asObservable()
    }

    private let activityEndedSubject = PublishSubject<Void>()
    var activityEnded: Observable<Void> {
        activityEndedSubject.asObservable()
    }

    // MARK: - Permission Check

    func checkActivityAuthorizationStatus() -> Observable<Bool> {
        return Observable.create { observer in
            let authInfo = ActivityAuthorizationInfo()
            let isEnabled = authInfo.areActivitiesEnabled
            print("[LiveActivity] 🔐 Authorization check: \(isEnabled ? "Enabled" : "Disabled")")
            observer.onNext(isEnabled)
            observer.onCompleted()
            return Disposables.create()
        }
    }

    func getActiveActivities() -> [Activity<ReadingTimerAttributes>] {
        return Activity<ReadingTimerAttributes>.activities
    }

    // MARK: - Start Activity

    func startActivity(
        bookTitle: String,
        targetMinutes: Int,
        sessionStartTime: Date
    ) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            let authInfo = ActivityAuthorizationInfo()
            print("[LiveActivity] 📱 Authorization status: \(authInfo.areActivitiesEnabled)")

            guard authInfo.areActivitiesEnabled else {
                print("[LiveActivity] ❌ Activities are NOT enabled")
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
                    timerStartTime: sessionStartTime,
                    pausedElapsedSeconds: 0,
                    targetSeconds: targetSeconds,
                    isPaused: false,
                    isCompleted: false
                )

                print("[LiveActivity] 🚀 Requesting activity:")
                print("  - bookTitle: \(bookTitle)")
                print("  - targetMinutes: \(targetMinutes) (\(targetSeconds)s)")
                print("  - sessionStartTime: \(sessionStartTime)")

                // staleDate를 설정하여 시스템이 더 자주 업데이트하도록 힌트 제공
                let staleDate = Calendar.current.date(byAdding: .second, value: targetSeconds, to: sessionStartTime)
                print("  - staleDate: \(staleDate?.description ?? "nil")")

                // 타이머 종료 시간에 자동으로 닫히도록 설정
                let content = ActivityContent(
                    state: initialState,
                    staleDate: staleDate,
                    relevanceScore: 1.0
                )

                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )

                print("[LiveActivity] ✅ Activity started successfully!")
                print("  - activity.id: \(activity.id)")
                print("  - activity.activityState: \(activity.activityState)")

                self?.currentActivity = activity

                // Activity 상태 변화 관찰
                self?.observeActivityState(activity)

                observer.onNext(())
                observer.onCompleted()
            } catch {
                print("[LiveActivity] ❌ Failed to start activity:")
                print("  - error: \(error)")
                print("  - error localized: \(error.localizedDescription)")
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    // MARK: - Update Activity

    func updateActivity(
        elapsedSeconds: Int,
        isPaused: Bool,
        targetSeconds: Int,
        sessionStartTime: Date? = nil,
        pausedDuration: Int = 0
    ) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let activity = self?.currentActivity else {
                print("[LiveActivity] No active activity to update")
                observer.onError(LiveActivityError.noActiveActivity)
                return Disposables.create()
            }

            // timerStartTime 계산
            let timerStartTime: Date?
            if isPaused {
                timerStartTime = nil
            } else if let sessionStart = sessionStartTime {
                // 절대 기준 시간 사용: sessionStartTime + pausedDuration
                timerStartTime = sessionStart.addingTimeInterval(TimeInterval(pausedDuration))
            } else {
                // fallback: 이전 방식 (하위 호환성)
                timerStartTime = Date().addingTimeInterval(-TimeInterval(elapsedSeconds))
            }

            let newState = ReadingTimerAttributes.ContentState(
                timerStartTime: timerStartTime,
                pausedElapsedSeconds: elapsedSeconds,
                targetSeconds: targetSeconds,
                isPaused: isPaused,
                isCompleted: false
            )

            Task {
                do {
                    // staleDate 설정 - 타이머 종료 시간
                    let remainingSeconds = targetSeconds - elapsedSeconds
                    let staleDate = Calendar.current.date(byAdding: .second, value: remainingSeconds, to: Date())

                    await activity.update(.init(state: newState, staleDate: staleDate))
                    print("[LiveActivity] Updated: \(elapsedSeconds)s elapsed, paused: \(isPaused)")
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    print("[LiveActivity] Failed to update: \(error)")
                    observer.onError(error)
                }
            }

            return Disposables.create()
        }
    }

    // MARK: - End Activity

    func endActivity() -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let activity = self?.currentActivity else {
                print("[LiveActivity] No active activity to end")
                observer.onNext(())
                observer.onCompleted()
                return Disposables.create()
            }

            Task {
                do {
                    // 완료 상태로 업데이트
                    let completedState = ReadingTimerAttributes.ContentState(
                        timerStartTime: nil,
                        pausedElapsedSeconds: activity.content.state.pausedElapsedSeconds,
                        targetSeconds: activity.content.state.targetSeconds,
                        isPaused: false,
                        isCompleted: true  // 완료 상태로 설정
                    )

                    await activity.end(
                        .init(state: completedState, staleDate: nil),
                        dismissalPolicy: .after(.now.addingTimeInterval(60 * 60))  // 1시간 후 제거
                    )
                    print("[LiveActivity] Activity ended with completion state")
                    self?.cleanupActivity()
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    print("[LiveActivity] Failed to end activity: \(error)")
                    self?.cleanupActivity()
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    // MARK: - Activity State Observer

    private func observeActivityState(_ activity: Activity<ReadingTimerAttributes>) {
        // 이전 관찰자 취소
        activityStateObserver?.cancel()

        // 새 관찰자 시작
        activityStateObserver = Task {
            for await state in activity.activityStateUpdates {
                print("[LiveActivity] 📊 Activity state changed: \(state)")

                switch state {
                case .dismissed:
                    print("[LiveActivity] 🗑️ User dismissed the Live Activity")
                    self.activityDismissedSubject.onNext(())
                    self.cleanupActivity()

                case .ended:
                    print("[LiveActivity] ⏹️ Activity ended")
                    self.activityEndedSubject.onNext(())
                    self.cleanupActivity()

                case .stale:
                    print("[LiveActivity] ⏰ Activity became stale (8 hour limit reached)")
                    self.activityStaleSubject.onNext(())
                    // stale 상태에서는 정리하지 않고 계속 유지 (새로 생성할 수 있음)

                case .active:
                    print("[LiveActivity] ✅ Activity is active")
                    break

                @unknown default:
                    break
                }
            }
        }
    }

    private func cleanupActivity() {
        print("[LiveActivity] 🧹 Cleaning up activity")
        activityStateObserver?.cancel()
        activityStateObserver = nil
        currentActivity = nil
    }

    // MARK: - Error

    enum LiveActivityError: Error {
        case notEnabled
        case noActiveActivity
    }
}
