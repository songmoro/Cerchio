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

    private init() {}

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("BookPhotos", isDirectory: true)
    }

    // MARK: - Directory Setup
    private func createImagesDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    // MARK: - Save Image
    func saveImage(_ image: UIImage, withName imageName: String) -> String? {
        createImagesDirectoryIfNeeded()

        let fileName = "\(imageName).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(fileName)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return nil
        }

        do {
            try imageData.write(to: imageURL)
            print("Image saved successfully at: \(imageURL.path)")
            // 파일명만 반환 (절대 경로가 아닌 상대 경로)
            return fileName
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Load Image
    func loadImage(fromPath path: String) -> UIImage? {
        // 파일명만 전달된 경우 전체 경로 구성
        let fullPath: String
        if path.contains("/") {
            // 절대 경로인 경우 (기존 데이터 호환성)
            fullPath = path
        } else {
            // 파일명만 있는 경우 전체 경로 구성
            fullPath = imagesDirectory.appendingPathComponent(path).path
        }
        return UIImage(contentsOfFile: fullPath)
    }

    // MARK: - Delete Image
    func deleteImage(atPath path: String) -> Bool {
        // 파일명만 전달된 경우 전체 경로 구성
        let fullPath: String
        if path.contains("/") {
            // 절대 경로인 경우
            fullPath = path
        } else {
            // 파일명만 있는 경우
            fullPath = imagesDirectory.appendingPathComponent(path).path
        }

        do {
            try FileManager.default.removeItem(atPath: fullPath)
            print("Image deleted successfully from: \(fullPath)")
            return true
        } catch {
            print("Failed to delete image: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Generate Unique Name
    func generateUniqueImageName(for bookId: String) -> String {
        let timestamp = Date().timeIntervalSince1970
        let randomSuffix = Int.random(in: 1000...9999)
        return "book_\(bookId)_\(Int(timestamp))_\(randomSuffix)"
    }

    // MARK: - Get All Images for Book
    func getImagePaths(for bookId: String) -> [String] {
        createImagesDirectoryIfNeeded()

        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: imagesDirectory.path)
            let bookImageFiles = files.filter { $0.contains("book_\(bookId)_") && $0.hasSuffix(".jpg") }
            // 파일명만 반환 (절대 경로가 아닌 상대 경로)
            return bookImageFiles
        } catch {
            print("Failed to get image paths: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Delete All Images for Book
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
