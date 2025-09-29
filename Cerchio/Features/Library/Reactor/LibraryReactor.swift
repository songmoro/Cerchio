//
//  LibraryReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 9/26/25.
//

import Foundation
import ReactorKit
import RxSwift

final class LibraryReactor: Reactor {
    enum Action {
        case loadBooks
        case refreshBooks
    }

    enum Mutation {
        case setBooks([Book])
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var books: [Book] = Book.sample
        var isLoading: Bool = false
        var error: Error?
    }

    let initialState = State()

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadBooks:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                Observable.just(.setBooks(Book.sample))
                    .delay(.milliseconds(LibraryConstants.Animation.initialLoadDelayMilliseconds), scheduler: MainScheduler.instance),
                Observable.just(.setLoading(false))
            ])

        case .refreshBooks:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                Observable.just(.setBooks(Book.sample))
                    .delay(.milliseconds(LibraryConstants.Animation.refreshDelayMilliseconds), scheduler: MainScheduler.instance),
                Observable.just(.setLoading(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setBooks(let books):
            newState.books = books

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error
        }

        return newState
    }
}
