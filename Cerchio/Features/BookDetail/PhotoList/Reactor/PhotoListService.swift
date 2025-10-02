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

    // MARK: - Photo Operations

    /// Realm에서 사진 메타데이터만 로드
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

    /// 사진 메타데이터와 이미지를 비동기로 로드
    /// - 메인 스레드: Realm 접근, 경로 추출
    /// - 백그라운드: 이미지 파일 로딩 (병렬)
    func loadPhotosWithImages(bookId: String) async throws -> [PhotoWithImage] {
        // 1. 메인 스레드에서 Realm 접근하여 경로와 메타데이터 추출
        let photoData = try await MainActor.run {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)

            // 메인 스레드에서 필요한 데이터만 추출 (가벼운 작업)
            // Array로 변환하여 Sendable 준수
            return Array(photos.map { (id: String(describing: $0.id), path: $0.localImagePath) })
        }

        // 2. 백그라운드에서 이미지 로딩 (병렬 처리)
        let photosWithImages = await withTaskGroup(of: (index: Int, result: PhotoWithImage?).self) { group in
            for (index, data) in photoData.enumerated() {
                group.addTask {
                    // 백그라운드에서 이미지 로드
                    if let image = await ImageStorageManager.shared.loadImage(fromPath: data.path) {
                        return (index, PhotoWithImage(id: data.id, image: image, path: data.path))
                    }
                    return (index, nil)
                }
            }

            // 원본 순서 유지를 위해 index와 함께 저장
            var indexedPhotos: [(index: Int, photo: PhotoWithImage)] = []
            for await result in group {
                if let photo = result.result {
                    indexedPhotos.append((result.index, photo))
                }
            }

            // 원본 순서대로 정렬하여 반환
            return indexedPhotos
                .sorted { $0.index < $1.index }
                .map { $0.photo }
        }

        return photosWithImages
    }

    /// 이미지 경로 목록에서 이미지 로드 (백그라운드 병렬 처리)
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

    // MARK: - Delete Photo

    func deletePhoto(_ photoId: String) -> Observable<Void> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                guard let objectId = try? ObjectId(string: photoId),
                      let photo = realm.object(ofType: RealmPhoto.self, forPrimaryKey: objectId) else {
                    observer.onError(NSError(domain: "PhotoNotFound", code: 404))
                    return Disposables.create()
                }

                // 로컬 파일 삭제
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

// MARK: - Supporting Types

struct PhotoWithImage {
    let id: String
    let image: UIImage
    let path: String
}
