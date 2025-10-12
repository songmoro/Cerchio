//
//  EditBookInfoReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import Foundation
import ReactorKit
import RxSwift

final class EditBookInfoReactor: Reactor {
    enum Action {
        case updateTitle(String)
        case updateAuthor(String)
        case updateCoverImage(String)
        case save
    }

    enum Mutation {
        case setTitle(String)
        case setAuthor(String)
        case setCoverImage(String)
        case setSaveInProgress(Bool)
        case setSaveSuccess(Bool)
    }

    struct State {
        var book: Book
        var customTitle: String
        var customAuthor: String
        var customCoverImagePath: String?
        var isSaveInProgress: Bool = false
        var isSaveSuccess: Bool = false
    }

    let initialState: State
    private let bookRepository: BookRepositoryProtocol

    init(book: Book, bookRepository: BookRepositoryProtocol) {
        self.bookRepository = bookRepository
        self.initialState = State(
            book: book,
            customTitle: book.customTitle ?? book.title,
            customAuthor: book.customAuthor ?? book.author,
            customCoverImagePath: book.customCoverImagePath
        )
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .updateTitle(let title):
            return .just(.setTitle(title))

        case .updateAuthor(let author):
            return .just(.setAuthor(author))

        case .updateCoverImage(let imagePath):
            return .just(.setCoverImage(imagePath))

        case .save:
            return saveBookInfo()
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setTitle(let title):
            newState.customTitle = title

        case .setAuthor(let author):
            newState.customAuthor = author

        case .setCoverImage(let imagePath):
            newState.customCoverImagePath = imagePath

        case .setSaveInProgress(let inProgress):
            newState.isSaveInProgress = inProgress

        case .setSaveSuccess(let success):
            newState.isSaveSuccess = success
        }

        return newState
    }

    private func saveBookInfo() -> Observable<Mutation> {
        let bookId = currentState.book.id
        let customTitle = currentState.customTitle
        let customAuthor = currentState.customAuthor
        let customCoverImagePath = currentState.customCoverImagePath

        return .concat([
            .just(.setSaveInProgress(true)),
            bookRepository.updateBookCustomInfo(
                bookId: bookId,
                customTitle: customTitle,
                customAuthor: customAuthor,
                customCoverImagePath: customCoverImagePath
            )
            .flatMap { _ -> Observable<Mutation> in
                return .concat([
                    .just(.setSaveInProgress(false)),
                    .just(.setSaveSuccess(true))
                ])
            }
            .catch { error in
                print("❌ Failed to save book info: \(error)")
                return .just(.setSaveInProgress(false))
            }
        ])
    }
}
