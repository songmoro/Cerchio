//
//  BookDetailService.swift
//  Cerchio
//
//  Created by Claude on 10/2/25.
//

import UIKit
import RxSwift
import RealmSwift

final class BookDetailService {
    private let serviceFactory: ServiceFactory

    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    // MARK: - Photo Operations

    func loadPhotos(bookId: String) -> Observable<[Photo]> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let photos = realm.objects(RealmPhoto.self)
                    .filter("bookId == %@", bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                let photoModels = photos.map { $0.toPhoto() }
                observer.onNext(Array(photoModels))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func loadPhotoImages(photos: [RealmPhoto]) async -> [UIImage] {
        let imagePaths = photos.map { $0.localImagePath }
        return await loadImages(from: imagePaths)
    }

    private func loadImages(from paths: [String]) async -> [UIImage] {
        await withTaskGroup(of: UIImage?.self) { group in
            for path in paths {
                group.addTask {
                    ImageStorageManager.shared.loadImage(fromPath: path)
                }
            }

            var images: [UIImage] = []
            for await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            return images
        }
    }

    // MARK: - Quote Operations

    func loadQuotes(bookId: String) -> Observable<[RealmQuote]> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let quotes = realm.objects(RealmQuote.self)
                    .filter("bookId == %@", bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                observer.onNext(Array(quotes))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    // MARK: - Tag Operations

    func loadTags(bookId: String) -> Observable<[RealmTag]> {
        let tagRepository = serviceFactory.createTagRepository()
        return tagRepository.getTags(for: bookId)
    }

    // MARK: - Photo Save

    func savePhoto(_ image: UIImage, bookId: String) -> Observable<RealmPhoto> {
        return Observable.create { observer in
            // 로컬 저장
            let imageName = ImageStorageManager.shared.generateUniqueImageName(for: bookId)
            guard let localPath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
                observer.onError(NSError(domain: "ImageSaveError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image locally"]))
                return Disposables.create()
            }

            // Realm 저장
            let realmPhoto = RealmPhoto(bookId: bookId, localImagePath: localPath)

            do {
                let realm = try Realm()
                try realm.write {
                    realm.add(realmPhoto)
                }
                observer.onNext(realmPhoto)
                observer.onCompleted()
            } catch {
                // 실패 시 로컬 이미지 삭제
                ImageStorageManager.shared.deleteImage(atPath: localPath)
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
}
