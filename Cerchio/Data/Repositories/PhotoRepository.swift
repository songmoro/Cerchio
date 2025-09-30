//
//  PhotoRepository.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol PhotoRepositoryProtocol {
    func getAllPhotos() -> Observable<[RealmPhoto]>
    func getPhotos(for bookId: String) -> Observable<[RealmPhoto]>
    func savePhoto(_ photo: RealmPhoto) -> Observable<RealmPhoto>
    func deletePhoto(_ photo: RealmPhoto) -> Observable<Void>
    func deletePhotos(for bookId: String) -> Observable<Void>
    func findPhotoByImagePath(_ imagePath: String, bookId: String) -> Observable<RealmPhoto?>
}

final class PhotoRepository: BaseRepository<RealmPhoto>, PhotoRepositoryProtocol {

    // MARK: - PhotoRepositoryProtocol
    func getAllPhotos() -> Observable<[RealmPhoto]> {
        return fetch()
    }

    func getPhotos(for bookId: String) -> Observable<[RealmPhoto]> {
        return filter("bookId == %@", bookId)
    }

    func savePhoto(_ photo: RealmPhoto) -> Observable<RealmPhoto> {
        return save(photo)
    }

    func deletePhoto(_ photo: RealmPhoto) -> Observable<Void> {
        return delete(photo)
    }

    func deletePhotos(for bookId: String) -> Observable<Void> {
        return performWriteTransaction {
            let photosToDelete = self.realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            self.realm.delete(photosToDelete)
            return ()
        }
    }

    func findPhotoByImagePath(_ imagePath: String, bookId: String) -> Observable<RealmPhoto?> {
        return performOnMainThread {
            let photos = self.realm.objects(RealmPhoto.self).filter("bookId == %@ AND localImagePath == %@", bookId, imagePath)
            return photos.first
        }
    }

    // MARK: - Helper Methods
    private func performWriteTransaction<U>(_ operation: @escaping () throws -> U) -> Observable<U> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let result = try self.realm.write {
                        try operation()
                    }
                    observer.onNext(result)
                    observer.onCompleted()
                } catch {
                    observer.onError(RepositoryError.transactionFailed(error))
                }
            }
            return Disposables.create()
        }
    }

    private func performOnMainThread<U>(_ operation: @escaping () -> U) -> Observable<U> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                let result = operation()
                observer.onNext(result)
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}