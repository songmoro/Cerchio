//
//  ResetAndDeleteReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import Foundation
import ReactorKit
import RxSwift

final class ResetAndDeleteReactor: Reactor {
    enum Action {
        case resetBookInfo
        case resetReadingRecords
        case deleteBook
    }

    enum Mutation {
        case setResetInProgress(Bool)
        case setResetSuccess(Bool)
        case setDeleteInProgress(Bool)
        case setDeleteSuccess(Bool)
    }

    struct State {
        var book: Book
        var isResetInProgress: Bool = false
        var isResetSuccess: Bool = false
        var isDeleteInProgress: Bool = false
        var isDeleteSuccess: Bool = false
    }

    let initialState: State
    private let bookRepository: BookRepositoryProtocol
    private let serviceFactory: ServiceFactory

    init(book: Book, bookRepository: BookRepositoryProtocol, serviceFactory: ServiceFactory) {
        self.bookRepository = bookRepository
        self.serviceFactory = serviceFactory
        self.initialState = State(book: book)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .resetBookInfo:
            return resetBookInfo()

        case .resetReadingRecords:
            return resetReadingRecords()

        case .deleteBook:
            return deleteBook()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setResetInProgress(let inProgress):
            newState.isResetInProgress = inProgress

        case .setResetSuccess(let success):
            newState.isResetSuccess = success

        case .setDeleteInProgress(let inProgress):
            newState.isDeleteInProgress = inProgress

        case .setDeleteSuccess(let success):
            newState.isDeleteSuccess = success
        }

        return newState
    }

    private func resetBookInfo() -> Observable<Mutation> {
        let bookId = currentState.book.id

        return .concat([
            .just(.setResetInProgress(true)),
            bookRepository.updateBookCustomInfo(
                bookId: bookId,
                customTitle: "",
                customAuthor: "",
                customCoverImagePath: nil
            )
            .flatMap { _ -> Observable<Mutation> in
                return .concat([
                    .just(.setResetInProgress(false)),
                    .just(.setResetSuccess(true))
                ])
            }
            .catch { error in
                print(" Failed to reset book info: \(error)")
                return .just(.setResetInProgress(false))
            }
        ])
    }

    private func resetReadingRecords() -> Observable<Mutation> {
        let bookId = currentState.book.id
        let sessionRepository = serviceFactory.createReadingSessionRepository()

        return .concat([
            .just(.setResetInProgress(true)),
            sessionRepository.deleteAllSessionsForBook(bookId: bookId)
                .flatMap { _ -> Observable<Mutation> in
                    return .concat([
                        .just(.setResetInProgress(false)),
                        .just(.setResetSuccess(true))
                    ])
                }
                .catch { error in
                    print(" Failed to reset reading records: \(error)")
                    return .just(.setResetInProgress(false))
                }
        ])
    }

    private func deleteBook() -> Observable<Mutation> {
        let isbn = currentState.book.isbn

        return .concat([
            .just(.setDeleteInProgress(true)),
            bookRepository.deleteBookByISBN(isbn)
                .flatMap { _ -> Observable<Mutation> in
                    return .concat([
                        .just(.setDeleteInProgress(false)),
                        .just(.setDeleteSuccess(true))
                    ])
                }
                .catch { error in
                    print(" Failed to delete book: \(error)")
                    return .just(.setDeleteInProgress(false))
                }
        ])
    }
}
