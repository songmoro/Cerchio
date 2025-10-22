//
//  BookDetailPerformanceTests.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import XCTest
import UIKit
import RealmSwift
import RxSwift
@testable import Cerchio

// MARK: - Book Detail Performance Tests
@MainActor
final class BookDetailPerformanceTests: XCTestCase {

    var realm: Realm!
    var service: BookDetailService!
    let disposeBag = DisposeBag()
    var testImagePaths: [String] = []

    // MARK: - Setup & Teardown

    
    override func setUp() {
        super.setUp()

        var config = Realm.Configuration()
        config.inMemoryIdentifier = "test-\(UUID().uuidString)"
        Realm.Configuration.defaultConfiguration = config

        do {
            realm = try Realm(configuration: config)
            service = BookDetailService(serviceFactory: TestRealmProvider.createTestServiceFactory())
        } catch {
            XCTFail("Failed to setup: \(error)")
        }
    }

    override func tearDown() {
        // 테스트 이미지 정리
        for path in testImagePaths {
            _ = ImageStorageManager.shared.deleteImage(atPath: path)
        }
        testImagePaths.removeAll()

        cleanupAllTestImages()

        do {
            try realm.write {
                realm.deleteAll()
            }
        } catch {
            print("Failed to clear test data: \(error)")
        }

        realm = nil
        service = nil

        super.tearDown()
    }

    // MARK: - Photo Loading Performance

    func testPerformance_Loading50Photos() async throws {
        // Given: 50장의 사진 저장
        let bookId = "test-book-id"
        let photos = try await createTestPhotosWithImages(count: 50, bookId: bookId)

        try realm.write {
            realm.add(photos)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]

        let options = XCTMeasureOptions()
        options.iterationCount = 3

        // When: 사진 로딩 성능 측정
        measure(metrics: metrics, options: options) {
            let expectation = expectation(description: "Load photos")

            Task {
                do {
                    let images = try await service.loadPhotosWithImages(bookId: bookId)
                    XCTAssertEqual(images.count, 50)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to load photos: \(error)")
                }
            }

            wait(for: [expectation], timeout: 15.0)
        }

        // Baseline 기준: 50장 병렬 로딩은 3초 이내
    }

    func testPerformance_Loading100Photos() async throws {
        // Given: 100장의 사진 저장
        let bookId = "test-book-100"
        let photos = try await createTestPhotosWithImages(count: 100, bookId: bookId)

        try realm.write {
            realm.add(photos)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric()
        ]

        measure(metrics: metrics) {
            let expectation = expectation(description: "Load 100 photos")

            Task {
                do {
                    let images = try await service.loadPhotosWithImages(bookId: bookId)
                    XCTAssertEqual(images.count, 100)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to load photos: \(error)")
                }
            }

            wait(for: [expectation], timeout: 30.0)
        }

        // Baseline 기준: 100장 병렬 로딩은 5초 이내
    }

    func testPerformance_ParallelImageLoading() async throws {
        // 병렬 이미지 로딩의 효율성 테스트
        let bookId = "parallel-test"
        let photos = try await createTestPhotosWithImages(count: 30, bookId: bookId)

        try realm.write {
            realm.add(photos)
        }

        let imagePaths = photos.map { $0.localImagePath }

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        // When: 병렬 로딩
        measure(metrics: metrics) {
            let expectation = expectation(description: "Parallel loading")

            Task {
                let images = await service.loadImagesInBackground(from: imagePaths)
                XCTAssertEqual(images.count, 30)
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 10.0)
        }

        // 병렬 처리로 인해 순차 로딩보다 빨라야 함
    }

    // MARK: - Quote Loading Performance

    func testPerformance_Loading500Quotes() throws {
        // Given: 500개의 인용구
        let bookId = "quotes-test"
        let quotes = createMockQuotes(count: 500, bookId: bookId)

        try realm.write {
            realm.add(quotes)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric()
        ]

        measure(metrics: metrics) {
            let expectation = expectation(description: "Load quotes")

            _ = service.loadQuotes(bookId: bookId)
                .subscribe(onNext: { quotes in
                    XCTAssertEqual(quotes.count, 500)
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 5.0)
        }

        // Baseline 기준: 500개 인용구 로딩은 300ms 이내
    }

    func testPerformance_Loading1000Quotes() throws {
        // Given: 1000개의 인용구 (극단적인 케이스)
        let bookId = "quotes-1000"
        let quotes = createMockQuotes(count: 1000, bookId: bookId)

        try realm.write {
            realm.add(quotes)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric()
        ]

        measure(metrics: metrics) {
            let expectation = expectation(description: "Load 1000 quotes")

            _ = service.loadQuotes(bookId: bookId)
                .subscribe(onNext: { quotes in
                    XCTAssertEqual(quotes.count, 1000)
                    expectation.fulfill()
                })

            wait(for: [expectation], timeout: 5.0)
        }
    }

    // MARK: - Mixed Data Loading Performance

    func testPerformance_LoadingMixedData() async throws {
        // Given: 책 상세 화면에서 필요한 모든 데이터
        let bookId = "mixed-test"

        let quotes = createMockQuotes(count: 100, bookId: bookId)
        let photos = try await createTestPhotosWithImages(count: 50, bookId: bookId)
        let tags = createMockTags(count: 10, bookId: bookId)

        try realm.write {
            realm.add(quotes)
            realm.add(photos)
            realm.add(tags)
        }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]

        // When: 모든 데이터를 동시에 로딩 (실제 화면 진입 시나리오)
        measure(metrics: metrics) {
            let expectation = expectation(description: "Load all data")

            Task {
                async let quotesLoad = service.loadQuotes(bookId: bookId).toAsync()
                async let photosLoad = service.loadPhotosWithImages(bookId: bookId)
                async let tagsLoad = service.loadTags(bookId: bookId).toAsync()

                do {
                    let (loadedQuotes, loadedPhotos, loadedTags) = try await (quotesLoad, photosLoad, tagsLoad)

                    XCTAssertEqual(loadedQuotes.count, 100)
                    XCTAssertEqual(loadedPhotos.count, 50)
                    XCTAssertEqual(loadedTags.count, 10)

                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to load data: \(error)")
                }
            }

            wait(for: [expectation], timeout: 20.0)
        }

        // Baseline 기준: 모든 데이터 병렬 로딩은 5초 이내
    }

    // MARK: - Photo Save Performance

    func testPerformance_Saving10PhotosSequentially() throws {
        let bookId = "save-test"
        let images = (0..<10).map { _ in createDummyImage() }

        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTStorageMetric()
        ]

        // When: 10장의 사진을 순차적으로 저장
        measure(metrics: metrics) {
            let expectation = expectation(description: "Save photos")
            expectation.expectedFulfillmentCount = 10

            for image in images {
                _ = service.savePhoto(image, bookId: bookId)
                    .subscribe(onNext: { photo in
                        self.testImagePaths.append(photo.localImagePath)
                        expectation.fulfill()
                    })
            }

            wait(for: [expectation], timeout: 10.0)
        }
    }

    // MARK: - Memory Efficiency Tests

    func testMemory_LoadingLargeImages() async throws {
        // 큰 이미지 로딩 시 메모리 사용량 확인
        let bookId = "large-images"

        // 큰 이미지 생성 (1920x1080)
        let largeImages = (0..<20).map { _ in
            createDummyImage(size: CGSize(width: 1920, height: 1080))
        }

        // 이미지 저장
        for (index, image) in largeImages.enumerated() {
            let imageName = "large_\(bookId)_\(index)"
            if let path = ImageStorageManager.shared.saveImage(image, withName: imageName) {
                let photo = RealmPhoto(bookId: bookId, localImagePath: path)
                try realm.write {
                    realm.add(photo)
                }
                testImagePaths.append(path)
            }
        }

        let metrics: [XCTMetric] = [
            XCTMemoryMetric()
        ]

        // When: 큰 이미지 로딩
        measure(metrics: metrics) {
            let expectation = expectation(description: "Load large images")

            Task {
                do {
                    let images = try await service.loadPhotosWithImages(bookId: bookId)
                    XCTAssertEqual(images.count, 20)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed: \(error)")
                }
            }

            wait(for: [expectation], timeout: 15.0)
        }
    }

    func testMemory_RepeatedPhotoLoading() async throws {
        // 반복적인 사진 로딩 시 메모리 누수 확인
        let bookId = "memory-test"
        let photos = try await createTestPhotosWithImages(count: 10, bookId: bookId)

        try realm.write {
            realm.add(photos)
        }

        let metrics: [XCTMetric] = [
            XCTMemoryMetric()
        ]

        // When: 20번 반복 로딩
        measure(metrics: metrics) {
            let expectation = expectation(description: "Repeated loading")
            expectation.expectedFulfillmentCount = 20

            for _ in 0..<20 {
                Task {
                    do {
                        _ = try await service.loadPhotosWithImages(bookId: bookId)
                        expectation.fulfill()
                    } catch {
                        XCTFail("Failed: \(error)")
                    }
                }
            }

            wait(for: [expectation], timeout: 30.0)
        }

        // Then: 메모리가 일정 수준 유지되어야 함
    }

    // MARK: - Helper Methods

    private func createTestPhotosWithImages(count: Int, bookId: String) async throws -> [RealmPhoto] {
        var photos: [RealmPhoto] = []

        for index in 0..<count {
            let image = createDummyImage()
            let imageName = "test_\(bookId)_\(index)_\(UUID().uuidString)"

            guard let path = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
                throw TestError.imageCreationFailed
            }

            testImagePaths.append(path)

            let photo = RealmPhoto(
                bookId: bookId,
                localImagePath: path,
                createdAt: Date().addingTimeInterval(TimeInterval(-index * 60))
            )
            photos.append(photo)
        }

        return photos
    }

    private func createDummyImage(size: CGSize = CGSize(width: 800, height: 600)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let text = "\(Int(size.width))x\(Int(size.height))" as NSString
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
