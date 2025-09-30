//
//  SettingsReactor.swift
//  Cerchio
//
//  Created by Claude on 9/30/25.
//

import Foundation
import ReactorKit
import RxSwift

final class SettingsReactor: Reactor {
    enum Action {
        case resetAllData
    }

    enum Mutation {
        case setResetting(Bool)
        case setError(Error?)
        case resetCompleted
    }

    struct State {
        var isResetting: Bool = false
        var error: Error?
        var resetCompleted: Bool = false
    }

    let initialState = State()
    private let bookRepository: BookRepositoryProtocol

    init(bookRepository: BookRepositoryProtocol) {
        self.bookRepository = bookRepository
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .resetAllData:
            return Observable.concat([
                Observable.just(.setResetting(true)),
                resetAllData()
                    .map { _ in .resetCompleted }
                    .catch { error in
                        print("❌ Failed to reset data: \(error.localizedDescription)")
                        return Observable.just(.setError(error))
                    },
                Observable.just(.setResetting(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setResetting(let isResetting):
            newState.isResetting = isResetting

        case .setError(let error):
            newState.error = error
            newState.resetCompleted = false

        case .resetCompleted:
            newState.resetCompleted = true
            newState.error = nil
        }

        return newState
    }

    private func resetAllData() -> Observable<Void> {
        return bookRepository.deleteAllData()
    }
}