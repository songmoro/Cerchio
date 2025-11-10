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
    typealias Action = Never
    typealias Mutation = Never
    struct State {
        var bookId: String
    }
    let initialState: State
    private let serviceFactory: ServiceFactory
    init(bookId: String, serviceFactory: ServiceFactory) {
        self.initialState = State(bookId: bookId)
        self.serviceFactory = serviceFactory
    }
}
