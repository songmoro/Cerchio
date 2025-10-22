//
//  TestRealmProvider.swift
//  CerchioTests
//
//  Created by 송재훈 on 10/3/25.
//

import XCTest
import Foundation
import RealmSwift
import RxSwift
@testable import Cerchio

// MARK: - Mock Network Client

final class MockNetworkClient: NetworkClientProtocol {
    func execute<T: NetworkRequest>(_ request: T) -> Observable<T.Response> {
        return Observable.error(NSError(domain: "MockNetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock network client - not implemented"]))
    }

    func execute<T: NetworkRequest>(_ request: T) -> Observable<APIResponse<T.Response>> {
        return Observable.error(NSError(domain: "MockNetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock network client - not implemented"]))
    }

    func executePaginated<T: NetworkRequest>(_ request: T) -> Observable<PaginatedResponse<T.Response>> {
        return Observable.error(NSError(domain: "MockNetworkClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock network client - not implemented"]))
    }
}

// MARK: - Test Realm Provider

/// Provides in-memory Realm instances for testing
@MainActor
final class TestRealmProvider {

    // MARK: - Shared Instance

    static let shared = TestRealmProvider()

    private init() {}

    // MARK: - Realm Configuration

    /// Creates a new in-memory Realm configuration with a unique identifier
    /// - Returns: Realm.Configuration for testing
    static func createInMemoryConfiguration() -> Realm.Configuration {
        var config = Realm.Configuration()
        config.inMemoryIdentifier = "test-\(UUID().uuidString)"
        return config
    }

    /// Creates a new in-memory Realm instance
    /// - Returns: Realm instance configured for testing
    /// - Throws: Realm initialization errors
    @MainActor
    static func createInMemoryRealm() throws -> Realm {
        let config = createInMemoryConfiguration()
        return try Realm(configuration: config)
    }

    // MARK: - Setup and Cleanup

    /// Sets up a test Realm with optional mock data
    /// - Parameters:
    ///   - books: Mock books to add
    ///   - tags: Mock tags to add
    ///   - quotes: Mock quotes to add
    ///   - photos: Mock photos to add
    /// - Returns: Configured Realm instance
    /// - Throws: Realm initialization or write errors
    @MainActor
    static func setupTestRealm(
        books: [RealmBook] = [],
        tags: [RealmTag] = [],
        quotes: [RealmQuote] = [],
        photos: [RealmPhoto] = []
    ) throws -> Realm {
        let realm = try createInMemoryRealm()

        try realm.write {
            realm.add(books)
            realm.add(tags)
            realm.add(quotes)
            realm.add(photos)
        }

        return realm
    }

    /// Clears all data from a Realm instance
    /// - Parameter realm: Realm instance to clear
    /// - Throws: Realm write errors
    @MainActor
    static func clearRealm(_ realm: Realm) throws {
        try realm.write {
            realm.deleteAll()
        }
    }

    // MARK: - Repository Factory

    /// Creates a BookRepository with a test Realm configuration
    /// - Parameter realm: Realm instance to use (creates new one if nil)
    /// - Returns: BookRepository configured for testing
    /// - Throws: Repository initialization errors
    @MainActor
    static func createTestBookRepository(realm: Realm? = nil) throws -> BookRepository {
        if let realm = realm {
            let config = realm.configuration
            Realm.Configuration.defaultConfiguration = config
        } else {
            Realm.Configuration.defaultConfiguration = createInMemoryConfiguration()
        }

        return try BookRepository()
    }

    /// Creates a TagRepository with a test Realm configuration
    @MainActor
    static func createTestTagRepository(realm: Realm? = nil) throws -> TagRepository {
        if let realm = realm {
            let config = realm.configuration
            Realm.Configuration.defaultConfiguration = config
        } else {
            Realm.Configuration.defaultConfiguration = createInMemoryConfiguration()
        }

        return try TagRepository()
    }

    /// Creates a QuoteRepository with a test Realm configuration
    @MainActor
    static func createTestQuoteRepository(realm: Realm? = nil) throws -> QuoteRepository {
        if let realm = realm {
            let config = realm.configuration
            Realm.Configuration.defaultConfiguration = config
        } else {
            Realm.Configuration.defaultConfiguration = createInMemoryConfiguration()
        }

        return try QuoteRepository()
    }

    /// Creates a PhotoRepository with a test Realm configuration
    @MainActor
    static func createTestPhotoRepository(realm: Realm? = nil) throws -> PhotoRepository {
        if let realm = realm {
            let config = realm.configuration
            Realm.Configuration.defaultConfiguration = config
        } else {
            Realm.Configuration.defaultConfiguration = createInMemoryConfiguration()
        }

        return try PhotoRepository()
    }

    // MARK: - ServiceFactory for Testing

    /// Creates a test ServiceFactory with in-memory Realm
    /// - Returns: ServiceFactory configured for testing
    @MainActor
    static func createTestServiceFactory() -> ServiceFactory {
        Realm.Configuration.defaultConfiguration = createInMemoryConfiguration()

        let mockNetworkClient = MockNetworkClient()
        let dependencies = DefaultServiceDependencies(networkClient: mockNetworkClient)

        return ServiceFactory(dependencies: dependencies)
    }
}

// MARK: - XCTestCase Extension

extension XCTestCase {

    /// Creates a test Realm for the current test
    @MainActor
    func createTestRealm() throws -> Realm {
        return try TestRealmProvider.createInMemoryRealm()
    }

    /// Creates a test Realm with pre-populated data
    @MainActor
    func createTestRealm(
        books: [RealmBook] = [],
        tags: [RealmTag] = [],
        quotes: [RealmQuote] = [],
        photos: [RealmPhoto] = []
    ) throws -> Realm {
        return try TestRealmProvider.setupTestRealm(
            books: books,
            tags: tags,
            quotes: quotes,
            photos: photos
        )
    }

    /// Clears all data from a test Realm
    @MainActor
    func clearTestRealm(_ realm: Realm) throws {
        try TestRealmProvider.clearRealm(realm)
    }

    /// Creates a test BookRepository
    @MainActor
    func createTestBookRepository(realm: Realm? = nil) throws -> BookRepository {
        return try TestRealmProvider.createTestBookRepository(realm: realm)
    }

    /// Creates a test TagRepository
    @MainActor
    func createTestTagRepository(realm: Realm? = nil) throws -> TagRepository {
        return try TestRealmProvider.createTestTagRepository(realm: realm)
    }

    /// Creates a test ServiceFactory
    @MainActor
    func createTestServiceFactory() -> ServiceFactory {
        return TestRealmProvider.createTestServiceFactory()
    }
}
