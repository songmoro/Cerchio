//
//  ReadingRecordReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import ReactorKit
import RxSwift

final class ReadingRecordReactor: Reactor {

    enum Action {
    }

    enum Mutation {
    }

    struct State {
        var bookId: String
    }

    // MARK: - Properties
    let initialState: State
    private let serviceFactory: ServiceFactory

    // MARK: - Initialization
    init(bookId: String, serviceFactory: ServiceFactory) {
        self.initialState = State(bookId: bookId)
        self.serviceFactory = serviceFactory
    }

    // MARK: - Reactor
    func mutate(action: Action) -> Observable<Mutation> {
        return .empty()
    }

    func reduce(state: State, mutation: Mutation) -> State {
        return state
    }
}
