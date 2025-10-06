//
//  ReadingSessionListReactor.swift
//  Cerchio
//
//  Created by Claude on 10/6/25.
//

import Foundation
import ReactorKit
import RxSwift
import RealmSwift

final class ReadingSessionListReactor: Reactor {

    enum Action {
        case loadSessions
        case deleteSession(String) // session ID
    }

    enum Mutation {
        case setSessions([ReadingSession])
        case setLoading(Bool)
        case setError(Error?)
        case removeSession(String)
    }

    struct State {
        var bookId: String
        var bookTitle: String
        var sessions: [ReadingSession] = []
        var isLoading: Bool = false
        var error: Error?
    }

    let initialState: State
    private let service: BookDetailService

    init(bookId: String, bookTitle: String, service: BookDetailService) {
        self.initialState = State(bookId: bookId, bookTitle: bookTitle)
        self.service = service
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadSessions:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                service.loadReadingSessions(for: currentState.bookId)
                    .map { realmSessions in
                        // RealmReadingSession을 ReadingSession DTO로 변환
                        let sessions = realmSessions.map { $0.toReadingSession() }
                        return Mutation.setSessions(sessions)
                    }
                    .catch { error in
                        print("❌ Failed to load sessions: \(error)")
                        return Observable.just(Mutation.setError(error))
                    },
                Observable.just(.setLoading(false))
            ])

        case .deleteSession(let sessionId):
            return deleteSessionFromRealm(sessionId)
                .map { Mutation.removeSession(sessionId) }
                .catch { error in
                    print("❌ Failed to delete session: \(error)")
                    return Observable.just(Mutation.setError(error))
                }
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setSessions(let sessions):
            newState.sessions = sessions

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error

        case .removeSession(let sessionId):
            newState.sessions.removeAll { $0.id == sessionId }
        }

        return newState
    }

    // MARK: - Private Methods

    private func deleteSessionFromRealm(_ sessionId: String) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                if let session = realm.object(ofType: RealmReadingSession.self, forPrimaryKey: sessionId) {
                    try realm.write {
                        realm.delete(session)
                    }
                    print("✅ Session deleted: \(sessionId)")
                    observer.onNext(())
                    observer.onCompleted()
                } else {
                    observer.onError(NSError(domain: "SessionNotFound", code: -1))
                }
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
}
