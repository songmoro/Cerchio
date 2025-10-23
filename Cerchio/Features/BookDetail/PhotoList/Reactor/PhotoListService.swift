//
//  PhotoListService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/2/25.
//

import UIKit
import RxSwift
import RealmSwift

final class PhotoListService {
    private let serviceFactory: ServiceFactory

    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    func loadPhotos(bookId: String) -> Observable<[RealmPhoto]> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let photos = realm.objects(RealmPhoto.self)
                    .filter("bookId == %@", bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                observer.onNext(Array(photos))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func loadPhotosWithImages(bookId: String) async throws -> [PhotoWithImage] {
        let photoData = try await MainActor.run {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)

            return Array(photos.map { (id: String(describing: $0.id), path: $0.localImagePath) })
        }

        let photosWithImages = await withTaskGroup(of: (index: Int, result: PhotoWithImage?).self) { group in
            for (index, data) in photoData.enumerated() {
                group.addTask {
                    if let image = await ImageStorageManager.shared.loadImage(fromPath: data.path) {
                        return (index, PhotoWithImage(id: data.id, image: image, path: data.path))
                    }
                    return (index, nil)
                }
            }

            var indexedPhotos: [(index: Int, photo: PhotoWithImage)] = []
            for await result in group {
                if let photo = result.result {
                    indexedPhotos.append((result.index, photo))
                }
            }

            return indexedPhotos
                .sorted { $0.index < $1.index }
                .map { $0.photo }
        }

        return photosWithImages
    }

    func loadImagesInBackground(from paths: [String]) async -> [UIImage] {
        await withTaskGroup(of: (index: Int, image: UIImage?).self) { group in
            for (index, path) in paths.enumerated() {
                group.addTask {
                    let image = await ImageStorageManager.shared.loadImage(fromPath: path)
                    return (index, image)
                }
            }

            var indexedImages: [(index: Int, image: UIImage)] = []
            for await result in group {
                if let image = result.image {
                    indexedImages.append((result.index, image))
                }
            }

            return indexedImages
                .sorted { $0.index < $1.index }
                .map { $0.image }
        }
    }

    func deletePhoto(_ photoId: String) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                guard let objectId = try? ObjectId(string: photoId),
                      let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: objectId) else {
                    observer.onError(NSError(domain: "PhotoNotFound", code: 404))
                    return Disposables.create()
                }

                _ = ImageStorageManager.shared.deleteImage(atPath: photo.localImagePath)

                try realm.write {
                    realm.delete(photo)
                }
                observer.onNext(())
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
}

struct PhotoWithImage {
    let id: String
    let image: UIImage
    let path: String
}
