//
//  ImageStorageManager.swift
//  Cerchio
//
//  Created by 송재훈 on 9/29/25.
//

import UIKit
import Foundation

class ImageStorageManager {
    static let shared = ImageStorageManager()

    private init() { }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("BookPhotos", isDirectory: true)
    }

    private func createImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    func saveImage(_ image: UIImage, withName imageName: String) -> String? {
        createImagesDirectoryIfNeeded()

        let fileName = "\(imageName).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(fileName)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }

        do {
            try imageData.write(to: imageURL)
            return fileName
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }

    func loadImage(fromPath path: String) -> UIImage? {
        let fullPath: String
        
        if path.contains("/") {
            fullPath = path
        } else {
            fullPath = imagesDirectory.appendingPathComponent(path).path
        }
        
        return UIImage(contentsOfFile: fullPath)
    }

    func deleteImage(atPath path: String) -> Bool {
        let fullPath: String
        
        if path.contains("/") {
            fullPath = path
        } else {
            fullPath = imagesDirectory.appendingPathComponent(path).path
        }

        do {
            try FileManager.default.removeItem(atPath: fullPath)
            return true
        } catch {
            print("Failed to delete image: \(error.localizedDescription)")
            return false
        }
    }

    func generateUniqueImageName(for bookId: String) -> String {
        let timestamp = Date().timeIntervalSince1970
        let randomSuffix = Int.random(in: 1000...9999)
        return "book_\(bookId)_\(Int(timestamp))_\(randomSuffix)"
    }

    func getImagePaths(for bookId: String) -> [String] {
        createImagesDirectoryIfNeeded()

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path)
            let bookImageFiles = files.filter { $0.contains("book_\(bookId)_") && $0.hasSuffix(".jpg") }
            
            return bookImageFiles
        } catch {
            print("Failed to get image paths: \(error.localizedDescription)")
            return []
        }
    }

    func deleteAllImages(for bookId: String) -> Bool {
        let imagePaths = getImagePaths(for: bookId)
        var allDeleted = true

        for path in imagePaths {
            if !deleteImage(atPath: path) {
                allDeleted = false
            }
        }

        return allDeleted
    }
}
