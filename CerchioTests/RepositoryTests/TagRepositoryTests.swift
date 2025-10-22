//
//  TagRepositoryTests.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import Testing
import Foundation
import RealmSwift
import RxSwift
@testable import Cerchio

// MARK: - Tag Repository Tests

@MainActor
@Suite("TagRepository Tests", .serialized)
struct TagRepositoryTests {

    // MARK: - Setup

    init() {
        Realm.Configuration.defaultConfiguration = TestRealmProvider.createInMemoryConfiguration()
    }

    // MARK: - CRUD Tests

    @Test("태그 저장 및 조회")
    func saveAndGetTags() async throws {
        let repository = try TagRepository()
        let bookId = "test-book-id"
        let tags = [
            RealmTag(bookId: bookId, tagName: "소설"),
            RealmTag(bookId: bookId, tagName: "추리"),
            RealmTag(bookId: bookId, tagName: "베스트셀러")
        ]

        // When: 태그 저장
        let savedTags = try await repository.saveTags(tags).toAsync()

        #expect(savedTags.count == 3)

        let fetchedTags = try await repository.getTags(for: bookId).toAsync()
        #expect(fetchedTags.count == 3)
        #expect(fetchedTags.map { $0.tagName }.contains("소설"))
        #expect(fetchedTags.map { $0.tagName }.contains("추리"))
    }

    @Test("특정 책의 태그만 조회")
    func getTagsForSpecificBook() async throws {
        let repository = try TagRepository()

        let book1Tags = [
            RealmTag(bookId: "book-1", tagName: "소설"),
            RealmTag(bookId: "book-1", tagName: "추리")
        ]

        let book2Tags = [
            RealmTag(bookId: "book-2", tagName: "자기계발"),
            RealmTag(bookId: "book-2", tagName: "경제")
        ]

        _ = try await repository.saveTags(book1Tags).toAsync()
        _ = try await repository.saveTags(book2Tags).toAsync()

        // When: book-1의 태그만 조회
        let fetchedTags = try await repository.getTags(for: "book-1").toAsync()

        #expect(fetchedTags.count == 2)
        #expect(fetchedTags.allSatisfy { $0.bookId == "book-1" })
        #expect(fetchedTags.map { $0.tagName }.contains("소설"))
        #expect(fetchedTags.map { $0.tagName }.contains("추리"))
    }

    @Test("모든 태그 조회")
    func getAllTags() async throws {
        let repository = try TagRepository()

        let tags = [
            RealmTag(bookId: "book-1", tagName: "소설"),
            RealmTag(bookId: "book-2", tagName: "추리"),
            RealmTag(bookId: "book-3", tagName: "SF")
        ]

        _ = try await repository.saveTags(tags).toAsync()

        let allTags = try await repository.getAllTags().toAsync()

        #expect(allTags.count == 3)
    }

    @Test("태그 삭제")
    func deleteTag() async throws {
        let repository = try TagRepository()
        let tag = RealmTag(bookId: "book-1", tagName: "삭제될 태그")

        let savedTags = try await repository.saveTags([tag]).toAsync()
        let tagToDelete = savedTags.first!

        try await repository.deleteTag(tagToDelete).toAsync()

        let remainingTags = try await repository.getTags(for: "book-1").toAsync()
        #expect(remainingTags.isEmpty)
    }

    @Test("특정 책의 모든 태그 삭제")
    func deleteTagsForBook() async throws {
        let repository = try TagRepository()

        let book1Tags = [
            RealmTag(bookId: "book-1", tagName: "소설"),
            RealmTag(bookId: "book-1", tagName: "추리"),
            RealmTag(bookId: "book-1", tagName: "베스트셀러")
        ]

        let book2Tags = [
            RealmTag(bookId: "book-2", tagName: "자기계발")
        ]

        _ = try await repository.saveTags(book1Tags).toAsync()
        _ = try await repository.saveTags(book2Tags).toAsync()

        // When: book-1의 모든 태그 삭제
        try await repository.deleteTags(for: "book-1").toAsync()

        let book1RemainingTags = try await repository.getTags(for: "book-1").toAsync()
        #expect(book1RemainingTags.isEmpty)

        let book2RemainingTags = try await repository.getTags(for: "book-2").toAsync()
        #expect(book2RemainingTags.count == 1)
    }

    // MARK: - Ordering Tests

    @Test("태그 생성 시간순 정렬 확인")
    func tagsOrderedByCreatedAt() async throws {
        let repository = try TagRepository()
        let bookId = "book-1"

        let now = Date()
        let tag1 = RealmTag(bookId: bookId, tagName: "첫번째", createdAt: now.addingTimeInterval(-100))
        let tag2 = RealmTag(bookId: bookId, tagName: "두번째", createdAt: now.addingTimeInterval(-50))
        let tag3 = RealmTag(bookId: bookId, tagName: "세번째", createdAt: now)

        _ = try await repository.saveTags([tag3, tag1, tag2]).toAsync() // 순서 섞어서 저장

        let tags = try await repository.getTags(for: bookId).toAsync()

        // Then: createdAt 오름차순으로 정렬되어야 함
        #expect(tags.count == 3)
        #expect(tags[0].tagName == "첫번째")
        #expect(tags[1].tagName == "두번째")
        #expect(tags[2].tagName == "세번째")
    }

    // MARK: - Duplicate Tags Tests

    @Test("동일한 책에 중복 태그 저장")
    func saveDuplicateTagsForSameBook() async throws {
        let repository = try TagRepository()
        let bookId = "book-1"

        let tags1 = [
            RealmTag(bookId: bookId, tagName: "소설"),
            RealmTag(bookId: bookId, tagName: "추리")
        ]

        let tags2 = [
            RealmTag(bookId: bookId, tagName: "소설"), // 중복
            RealmTag(bookId: bookId, tagName: "베스트셀러")
        ]

        _ = try await repository.saveTags(tags1).toAsync()
        _ = try await repository.saveTags(tags2).toAsync()

        let allTags = try await repository.getTags(for: bookId).toAsync()

        // Then: 중복 태그도 모두 저장됨 (비즈니스 로직에서 필터링해야 함)
        #expect(allTags.count == 4)
    }

    // MARK: - Edge Cases

    @Test("존재하지 않는 책의 태그 조회")
    func getTagsForNonExistentBook() async throws {
        let repository = try TagRepository()

        let tags = try await repository.getTags(for: "nonexistent-book").toAsync()

        #expect(tags.isEmpty)
    }

    @Test("빈 배열로 태그 저장")
    func saveEmptyTagsArray() async throws {
        let repository = try TagRepository()

        let savedTags = try await repository.saveTags([]).toAsync()

        #expect(savedTags.isEmpty)
    }

    @Test("태그 이름에 특수문자 포함")
    func saveTagsWithSpecialCharacters() async throws {
        let repository = try TagRepository()
        let bookId = "book-1"

        let tags = [
            RealmTag(bookId: bookId, tagName: "#소설"),
            RealmTag(bookId: bookId, tagName: "추리&미스터리"),
            RealmTag(bookId: bookId, tagName: "SF/판타지")
        ]

        _ = try await repository.saveTags(tags).toAsync()
        let fetchedTags = try await repository.getTags(for: bookId).toAsync()

        #expect(fetchedTags.count == 3)
        #expect(fetchedTags.map { $0.tagName }.contains("#소설"))
        #expect(fetchedTags.map { $0.tagName }.contains("추리&미스터리"))
    }
}
