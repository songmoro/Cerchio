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

    // MARK: - Start Activity

    func startActivity(
        bookTitle: String,
        targetMinutes: Int
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
                let now = Date()
                let attributes = ReadingTimerAttributes(
                    bookTitle: bookTitle,
                    sessionStartTime: now
                )

                let targetSeconds = targetMinutes * 60
                let initialState = ReadingTimerAttributes.ContentState(
                    timerStartTime: now,
                    pausedElapsedSeconds: 0,
                    targetSeconds: targetSeconds,
                    isPaused: false,
                    isCompleted: false
                )

                print("[LiveActivity] 🚀 Requesting activity:")
                print("  - bookTitle: \(bookTitle)")
                print("  - targetMinutes: \(targetMinutes) (\(targetSeconds)s)")
                print("  - timerStartTime: \(now)")

                // staleDate를 설정하여 시스템이 더 자주 업데이트하도록 힌트 제공
                let staleDate = Calendar.current.date(byAdding: .second, value: targetSeconds, to: now)
                print("  - staleDate: \(staleDate?.description ?? "nil")")

                let activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: initialState, staleDate: staleDate)
                )

                print("[LiveActivity] ✅ Activity started successfully!")
                print("  - activity.id: \(activity.id)")
                print("  - activity.activityState: \(activity.activityState)")

                self?.currentActivity = activity
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
        targetSeconds: Int
    ) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let activity = self?.currentActivity else {
                print("[LiveActivity] No active activity to update")
                observer.onError(LiveActivityError.noActiveActivity)
                return Disposables.create()
            }

            let newState = ReadingTimerAttributes.ContentState(
                timerStartTime: isPaused ? nil : Date(),
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
                    let finalState = activity.content.state
                    await activity.end(
                        .init(state: finalState, staleDate: nil),
                        dismissalPolicy: .immediate
                    )
                    print("[LiveActivity] Activity ended successfully")
                    self?.currentActivity = nil
                    observer.onNext(())
                    observer.onCompleted()
                } catch {
                    print("[LiveActivity] Failed to end activity: \(error)")
                    self?.currentActivity = nil
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        }
    }

    // MARK: - Error

    enum LiveActivityError: Error {
        case notEnabled
        case noActiveActivity
    }
}
