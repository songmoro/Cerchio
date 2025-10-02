//
//  BookDetailService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/2/25.
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

    /// 사진 메타데이터와 이미지를 비동기로 로드
    /// - 메인 스레드: Realm 접근, 경로 추출
    /// - 백그라운드: 이미지 파일 로딩 (병렬)
    func loadPhotosWithImages(bookId: String) async throws -> [UIImage] {
        // 1. 메인 스레드에서 Realm 접근하여 경로만 추출
        let imagePaths = try await MainActor.run {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)

            // 메인 스레드에서 경로만 추출 (가벼운 작업)
            return Array(photos.map { $0.localImagePath })
        }

        // 2. 백그라운드에서 이미지 로딩 (병렬 처리)
        return await loadImagesInBackground(from: imagePaths)
    }

    /// Realm 메타데이터만 로드 (Observable)
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

    /// 이미지 경로 목록에서 이미지 로드 (백그라운드 병렬 처리)
    func loadPhotoImages(photos: [RealmPhoto]) async -> [UIImage] {
        let imagePaths = photos.map { $0.localImagePath }
        return await loadImagesInBackground(from: imagePaths)
    }

    /// 백그라운드에서 이미지 병렬 로딩
    func loadImagesInBackground(from paths: [String]) async -> [UIImage] {
        await withTaskGroup(of: (index: Int, image: UIImage?).self) { group in
            for (index, path) in paths.enumerated() {
                group.addTask {
                    // 백그라운드에서 이미지 로드
                    let image = await ImageStorageManager.shared.loadImage(fromPath: path)
                    return (index, image)
                }
            }

            // 원본 순서 유지를 위해 index와 함께 저장
            var indexedImages: [(index: Int, image: UIImage)] = []
            for await result in group {
                if let image = result.image {
                    indexedImages.append((result.index, image))
                }
            }

            // 원본 순서대로 정렬하여 반환
            return indexedImages
                .sorted { $0.index < $1.index }
                .map { $0.image }
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
                _ = ImageStorageManager.shared.deleteImage(atPath: localPath)
                observer.onError(error)
            }

            return Disposables.create()
        }
    }
}
