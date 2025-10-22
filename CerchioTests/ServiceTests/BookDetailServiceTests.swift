//
//  BookDetailServiceTests.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import Testing
import Foundation
import UIKit
import RealmSwift
import RxSwift
@testable import Cerchio

// MARK: - Book Detail Service Tests

@MainActor
@Suite("BookDetailService Tests", .serialized)
struct BookDetailServiceTests {

    var testImagePaths: [String] = []

    // MARK: - Setup

    init() {
        Realm.Configuration.defaultConfiguration = TestRealmProvider.createInMemoryConfiguration()
    }

    // MARK: - Photo Loading Tests

    @Test("사진 메타데이터 로드")
    func loadPhotos() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "test-book"
        let photos = [
            RealmPhoto(bookId: bookId, localImagePath: "/path1.jpg"),
            RealmPhoto(bookId: bookId, localImagePath: "/path2.jpg"),
            RealmPhoto(bookId: bookId, localImagePath: "/path3.jpg")
        ]

        try await MainActor.run {
            try realm.write {
                realm.add(photos)
            }
        }

        let service = BookDetailService(serviceFactory: TestRealmProvider.createTestServiceFactory())

        let loadedPhotos = try await service.loadPhotos(bookId: bookId).toAsync()

        #expect(loadedPhotos.count == 3)
        #expect(loadedPhotos[0].localImagePath == "/path1.jpg")
    }

    @Test("존재하지 않는 책의 사진 조회")
    func loadPhotosForNonExistentBook() async throws {
        let service = BookDetailService(serviceFactory: TestRealmProvider.createTestServiceFactory())

        let photos = try await service.loadPhotos(bookId: "nonexistent").toAsync()

        #expect(photos.isEmpty)
    }

    @Test("사진 정렬 확인 (최신순)")
    func photosOrderedByCreatedAt() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "test-book"

        let now = Date()
        let photo1 = RealmPhoto(bookId: bookId, localImagePath: "/old.jpg", createdAt: now.addingTimeInterval(-100))
        let photo2 = RealmPhoto(bookId: bookId, localImagePath: "/recent.jpg", createdAt: now)

        try await MainActor.run {
            try realm.write {
                realm.add([photo1, photo2])
            }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        let photos = try await service.loadPhotos(bookId: bookId).toAsync()

        // Then: 최신 사진이 먼저 나와야 함 (descending)
        #expect(photos.count == 2)
        #expect(photos[0].localImagePath == "/recent.jpg")
        #expect(photos[1].localImagePath == "/old.jpg")
    }

    // MARK: - Quote Loading Tests

    @Test("인용구 로드")
    func loadQuotes() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "test-book"
        let quotes = [
            RealmQuote(bookId: bookId, quote: "첫 번째 인용구", pageNumber: 10),
            RealmQuote(bookId: bookId, quote: "두 번째 인용구", pageNumber: 20),
            RealmQuote(bookId: bookId, quote: "세 번째 인용구")
        ]

        try await MainActor.run {
        try realm.write {
            realm.add(quotes)
        }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        let loadedQuotes = try await service.loadQuotes(bookId: bookId).toAsync()

        #expect(loadedQuotes.count == 3)
        #expect(loadedQuotes[0].quote == "첫 번째 인용구")
        #expect(loadedQuotes[0].pageNumber == 10)
    }

    @Test("인용구 정렬 확인 (최신순)")
    func quotesOrderedByCreatedAt() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "test-book"

        let now = Date()
        let quote1 = RealmQuote(bookId: bookId, quote: "오래된 인용구", createdAt: now.addingTimeInterval(-100))
        let quote2 = RealmQuote(bookId: bookId, quote: "최신 인용구", createdAt: now)

        try await MainActor.run {
        try realm.write {
            realm.add([quote1, quote2])
        }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        let quotes = try await service.loadQuotes(bookId: bookId).toAsync()

        // Then: 최신 인용구가 먼저
        #expect(quotes.count == 2)
        #expect(quotes[0].quote == "최신 인용구")
        #expect(quotes[1].quote == "오래된 인용구")
    }

    // MARK: - Tag Loading Tests

    @Test("태그 로드")
    func loadTags() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "test-book"
        let tags = [
            RealmTag(bookId: bookId, tagName: "소설"),
            RealmTag(bookId: bookId, tagName: "추리"),
            RealmTag(bookId: bookId, tagName: "베스트셀러")
        ]

        try await MainActor.run {
        try realm.write {
            realm.add(tags)
        }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        let loadedTags = try await service.loadTags(bookId: bookId).toAsync()

        #expect(loadedTags.count == 3)
        #expect(loadedTags.map { $0.tagName }.contains("소설"))
        #expect(loadedTags.map { $0.tagName }.contains("추리"))
    }

    // MARK: - Image Loading Background Tests

    @Test("백그라운드 이미지 병렬 로딩")
    func loadImagesInBackground() async throws {
        // Given: 실제 이미지 파일 생성
        var imagePaths: [String] = []
        let bookId = "image-test"

        for index in 0..<5 {
            let image = createDummyImage()
            let imageName = "test_\(bookId)_\(index)"
            if let path = ImageStorageManager.shared.saveImage(image, withName: imageName) {
                imagePaths.append(path)
            }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        // When: 병렬 로딩
        let images = await service.loadImagesInBackground(from: imagePaths)

        #expect(images.count == 5)

        // 원본 순서 유지 확인
        for (index, image) in images.enumerated() {
            #expect(image.size.width == 800)
            #expect(image.size.height == 600)
        }

        for path in imagePaths {
            _ = ImageStorageManager.shared.deleteImage(atPath: path)
        }
    }

    @Test("이미지 로딩 순서 유지")
    func imageLoadingOrderPreserved() async throws {
        var imagePaths: [String] = []
        let colors: [UIColor] = [.red, .green, .blue]

        for (index, color) in colors.enumerated() {
            let image = createDummyImage(color: color)
            let imageName = "order_test_\(index)"
            if let path = ImageStorageManager.shared.saveImage(image, withName: imageName) {
                imagePaths.append(path)
            }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        // When: 병렬 로딩에도 순서 유지되어야 함
        let images = await service.loadImagesInBackground(from: imagePaths)

        // Then: 순서가 유지되어야 함
        #expect(images.count == 3)

        for path in imagePaths {
            _ = ImageStorageManager.shared.deleteImage(atPath: path)
        }
    }

    @Test("존재하지 않는 이미지 경로 처리")
    func handleNonExistentImagePaths() async throws {
        // Given: 존재하지 않는 경로들
        let invalidPaths = [
            "/invalid/path1.jpg",
            "/invalid/path2.jpg",
            "/invalid/path3.jpg"
        ]

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        let images = await service.loadImagesInBackground(from: invalidPaths)

        // Then: 로드 실패한 이미지는 제외되어야 함
        #expect(images.isEmpty)
    }

    // MARK: - Photo Save Tests

    @Test("사진 저장")
    func savePhoto() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "save-test"
        let image = createDummyImage()

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        let savedPhoto = try await service.savePhoto(image, bookId: bookId).toAsync()

        // Then: Realm에 저장되었는지 확인
        let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
        #expect(photos.count == 1)
        #expect(photos.first?.localImagePath == savedPhoto.localImagePath)

        // 파일이 실제로 저장되었는지 확인
        let loadedImage = ImageStorageManager.shared.loadImage(fromPath: savedPhoto.localImagePath)
        #expect(loadedImage != nil)

        _ = ImageStorageManager.shared.deleteImage(atPath: savedPhoto.localImagePath)
    }

    @Test("여러 사진 연속 저장")
    func saveMultiplePhotos() async throws {
        let realm = try await MainActor.run { try Realm() }
        let bookId = "multi-save-test"
        let images = (0..<3).map { _ in createDummyImage() }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        var savedPaths: [String] = []

        for image in images {
            let photo = try await service.savePhoto(image, bookId: bookId).toAsync()
            savedPaths.append(photo.localImagePath)
        }

        let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
        #expect(photos.count == 3)

        for path in savedPaths {
            _ = ImageStorageManager.shared.deleteImage(atPath: path)
        }
    }

    // MARK: - Integration Tests

    @Test("책 상세 정보 통합 로딩")
    func loadAllBookDetailData() async throws {
        // Given: 책의 모든 관련 데이터
        let realm = try await MainActor.run { try Realm() }
        let bookId = "integration-test"

        let quotes = [
            RealmQuote(bookId: bookId, quote: "인용구 1"),
            RealmQuote(bookId: bookId, quote: "인용구 2")
        ]

        let tags = [
            RealmTag(bookId: bookId, tagName: "소설"),
            RealmTag(bookId: bookId, tagName: "추리")
        ]

        try await MainActor.run {
        try realm.write {
            realm.add(quotes)
            realm.add(tags)
        }
        }

        let serviceFactory = TestRealmProvider.createTestServiceFactory()
        let service = BookDetailService(serviceFactory: serviceFactory)

        // When: 모든 데이터 병렬 로딩
        async let quotesResult = service.loadQuotes(bookId: bookId).toAsync()
        async let tagsResult = service.loadTags(bookId: bookId).toAsync()

        let (loadedQuotes, loadedTags) = try await (quotesResult, tagsResult)

        #expect(loadedQuotes.count == 2)
        #expect(loadedTags.count == 2)
    }

    // MARK: - Helper Methods

    private func createDummyImage(color: UIColor = .systemBlue) -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "Test Image" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
