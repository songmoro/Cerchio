//
//  PhotoListReactor.swift
//  Cerchio
//
//  Created by Claude on 10/1/25.
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

    init(bookId: String) {
        self.initialState = State(bookId: bookId)
    }

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .loadPhotos:
            return Observable.concat([
                Observable.just(.setLoading(true)),
                loadPhotosFromRealm(),
                Observable.just(.setLoading(false))
            ])

        case .deletePhoto(let photoId):
            return Observable.concat([
                Observable.just(.setLoading(true)),
                deletePhotoFromRealm(photoId),
                loadPhotosFromRealm(),
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

    private func loadPhotosFromRealm() -> Observable<Mutation> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            do {
                let realm = try Realm()
                let realmPhotos = realm.objects(RealmPhoto.self)
                    .filter("bookId == %@", self.currentState.bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)
                let photos = realmPhotos.map { $0.toPhoto() }

                observer.onNext(.setPhotos(Array(photos)))
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }

    private func deletePhotoFromRealm(_ photoId: String) -> Observable<Mutation> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                guard let objectId = try? ObjectId(string: photoId),
                      let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: objectId) else {
                    observer.onNext(.setError(NSError(domain: "PhotoNotFound", code: 404)))
                    observer.onCompleted()
                    return Disposables.create()
                }

                // 로컬 파일 삭제
                ImageStorageManager.shared.deleteImage(atPath: photo.localImagePath)

                try realm.write {
                    realm.delete(photo)
                }
                observer.onCompleted()
            } catch {
                observer.onNext(.setError(error))
                observer.onCompleted()
            }

            return Disposables.create()
        }
    }
}
