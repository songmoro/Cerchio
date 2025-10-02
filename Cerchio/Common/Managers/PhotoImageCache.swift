//
//  PhotoImageCache.swift
//  Cerchio
//
//  Created by Claude on 10/2/25.
//

import UIKit

/// 사진 이미지 메모리 캐시 매니저
/// - 메인 스레드 블로킹을 방지하기 위해 이미지를 ID 기반으로 캐싱
/// - UIImage를 해시하지 않고 photoId만 사용
final class PhotoImageCache {
    static let shared = PhotoImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.cerchio.photoImageCache", attributes: .concurrent)

    private init() {
        // 메모리 제한 설정 (50MB)
        cache.totalCostLimit = 50 * 1024 * 1024
        // 항목 수 제한 (최대 100개)
        cache.countLimit = 100

        // 메모리 경고 시 캐시 비우기
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Cache Operations

    /// 이미지 캐시에서 가져오기
    func getImage(forPhotoId photoId: String) -> UIImage? {
        return queue.sync {
            return cache.object(forKey: photoId as NSString)
        }
    }

    /// 이미지를 캐시에 저장
    func setImage(_ image: UIImage, forPhotoId photoId: String) {
        queue.async(flags: .barrier) { [weak self] in
            // 이미지 크기를 cost로 계산 (대략적인 메모리 사용량)
            let cost = Int(image.size.width * image.size.height * 4) // RGBA
            self?.cache.setObject(image, forKey: photoId as NSString, cost: cost)
        }
    }

    /// 특정 이미지 캐시 제거
    func removeImage(forPhotoId photoId: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeObject(forKey: photoId as NSString)
        }
    }

    /// 전체 캐시 비우기
    @objc func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAllObjects()
        }
    }

    // MARK: - Batch Operations

    /// 여러 이미지를 백그라운드에서 로드하고 캐시에 저장
    func loadAndCacheImages(photoIds: [String], imagePaths: [String]) async {
        guard photoIds.count == imagePaths.count else { return }

        await withTaskGroup(of: Void.self) { group in
            for (photoId, imagePath) in zip(photoIds, imagePaths) {
                // 이미 캐시에 있으면 스킵
                if getImage(forPhotoId: photoId) != nil {
                    continue
                }

                group.addTask { [weak self] in
                    if let image = ImageStorageManager.shared.loadImage(fromPath: imagePath) {
                        self?.setImage(image, forPhotoId: photoId)
                    }
                }
            }
        }
    }
}
