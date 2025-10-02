//
//  PhotoListReactor.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation
import ReactorKit
import RxSwift
import RealmSwift

final class PhotoListReactor: Reactor {
    enum Action {
        case loadPhotos
        case deletePhoto(String) // ID로 삭제
    }

    enum Mutation {
        case setPhotos([Photo])
        case setLoading(Bool)
        case setError(Error?)
    }

    struct State {
        var bookId: String
        var photos: [Photo] = []
        var isLoading: Bool = false
        var error: Error?
    }

    let initialState: State
    private let service: PhotoListService

    init(bookId: String, service: PhotoListService) {
        self.initialState = State(bookId: bookId)
        self.service = service
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadPhotos:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                service.loadPhotos(bookId: currentState.bookId)
                    .map { photos in .setPhotos(photos.map { $0.toPhoto() }) }
                    .catch { error in
                        Observable.just(.setError(error))
                    },
                Observable.just(.setLoading(false))
            ])

        case .deletePhoto(let photoId):
            return Observable.concat([
                Observable.just(.setLoading(true)),
                service.deletePhoto(photoId)
                    .flatMap { [weak self] _ -> Observable<Mutation> in
                        guard let self = self else { return .empty() }
                        return self.service.loadPhotos(bookId: self.currentState.bookId)
                            .map { photos in .setPhotos(photos.map { $0.toPhoto() }) }
                    }
                    .catch { error in
                        Observable.just(.setError(error))
                    },
                Observable.just(.setLoading(false))
            ])
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state

        switch mutation {
        case .setPhotos(let photos):
            newState.photos = photos

        case .setLoading(let isLoading):
            newState.isLoading = isLoading

        case .setError(let error):
            newState.error = error
        }

        return newState
    }

}
