//
//  PhotoImageCache.swift
//  Cerchio
//
//  Created by 송재훈 on 10/2/25.
//

import UIKit

final class PhotoImageCache {
    static let shared = PhotoImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(label: "com.cerchio.photoImageCache", attributes: .concurrent)

    private var scopedPhotoIds: [String: Set<String>] = [:]
    private let scopeQueue = DispatchQueue(label: "com.cerchio.photoImageCache.scope", attributes: .concurrent)

    private init() {
        cache.totalCostLimit = 30 * 1024 * 1024
        cache.countLimit = 50

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleMemoryWarning() {
        clearCache()
    }

    func getImage(forPhotoId photoId: String) -> UIImage? {
        return queue.sync {
            return cache.object(forKey: photoId as NSString)
        }
    }

    func setImage(_ image: UIImage, forPhotoId photoId: String, scope: String? = nil) {
        queue.async(flags: .barrier) { [weak self] in
            let cost = Int(image.size.width * image.size.height * 4)
            self?.cache.setObject(image, forKey: photoId as NSString, cost: cost)
        }

        if let scope = scope {
            scopeQueue.async(flags: .barrier) { [weak self] in
                self?.scopedPhotoIds[scope, default: []].insert(photoId)
            }
        }
    }

    func removeImage(forPhotoId photoId: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeObject(forKey: photoId as NSString)
        }

        scopeQueue.async(flags: .barrier) { [weak self] in
            self?.scopedPhotoIds.forEach { key, _ in
                self?.scopedPhotoIds[key]?.remove(photoId)
            }
        }
    }

    @objc func clearCache() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAllObjects()
        }

        scopeQueue.async(flags: .barrier) { [weak self] in
            self?.scopedPhotoIds.removeAll()
        }
    }

    func clearScope(_ scopeId: String) {
        scopeQueue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let photoIds = self.scopedPhotoIds[scopeId] else {
                return
            }

            self.queue.async(flags: .barrier) { [weak self] in
                photoIds.forEach { photoId in
                    self?.cache.removeObject(forKey: photoId as NSString)
                }
            }

            self.scopedPhotoIds.removeValue(forKey: scopeId)
        }
    }

    func registerScope(_ scopeId: String, photoIds: [String]) {
        scopeQueue.async(flags: .barrier) { [weak self] in
            self?.scopedPhotoIds[scopeId] = Set(photoIds)
        }
    }

    func loadAndCacheImages(photoIds: [String], imagePaths: [String], scope: String? = nil) async {
        guard photoIds.count == imagePaths.count else { return }

        await withTaskGroup(of: Void.self) { group in
            for (photoId, imagePath) in zip(photoIds, imagePaths) {
                if getImage(forPhotoId: photoId) != nil {
                    continue
                }

                group.addTask { [weak self] in
                    if let image = await ImageStorageManager.shared.loadImage(fromPath: imagePath) {
                        await self?.setImage(image, forPhotoId: photoId, scope: scope)
                    }
                }
            }
        }
    }
}
