//
//  SettingsReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import Foundation
import ReactorKit
import RxSwift

final class SettingsReactor: Reactor {
    enum Action {
        case resetAllData
        case changeLanguage(AppLanguage)
    }

    enum Mutation {
        case setResetting(Bool)
        case setError(Error?)
        case resetCompleted
        case languageChanged(AppLanguage)
    }

    struct State {
        var isResetting: Bool = false
        var error: Error?
        var resetCompleted: Bool = false
        var currentLanguage: AppLanguage = LanguageManager.shared.currentLanguage
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

        case .changeLanguage(let language):
            LanguageManager.shared.setLanguage(language)
            return Observable.just(.languageChanged(language))
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

        case .languageChanged(let language):
            newState.currentLanguage = language
        }

        return newState
    }

    private func resetAllData() -> Observable<Void> {
        return bookRepository.deleteAllData()
    }
}
