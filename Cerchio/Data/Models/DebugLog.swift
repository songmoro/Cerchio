//
//  DebugLog.swift
//  Cerchio
//
//  Created by 송재훈 on 10/7/25.
//

import Foundation
import RealmSwift

// MARK: - Log Level

enum LogLevel: String, Codable, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"

    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// MARK: - Domain Model

nonisolated struct DebugLog: Hashable, Sendable {
    let id: String
    let level: LogLevel
    let category: String
    let message: String
    let file: String
    let function: String
    let line: Int
    let timestamp: Date
    let metadata: [String: String]?

    init(
        id: String = UUID().uuidString,
        level: LogLevel,
        category: String,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.level = level
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Realm Model

final class RealmDebugLog: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var level: String
    @Persisted var category: String
    @Persisted var message: String
    @Persisted var file: String
    @Persisted var function: String
    @Persisted var line: Int
    @Persisted var timestamp: Date
    @Persisted var metadataJSON: String?

    convenience init(
        id: String = UUID().uuidString,
        level: LogLevel,
        category: String,
        message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        timestamp: Date = Date(),
        metadata: [String: String]? = nil
    ) {
        self.init()
        self.id = id
        self.level = level.rawValue
        self.category = category
        self.message = message
        self.file = file
        self.function = function
        self.line = line
        self.timestamp = timestamp

        if let metadata = metadata,
           let jsonData = try? JSONEncoder().encode(metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.metadataJSON = jsonString
        }
    }

    func toDebugLog() -> DebugLog {
        var metadata: [String: String]?
        if let jsonString = metadataJSON,
           let jsonData = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String: String].self, from: jsonData) {
            metadata = decoded
        }

        return DebugLog(
            id: id,
            level: LogLevel(rawValue: level) ?? .debug,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line,
            timestamp: timestamp,
            metadata: metadata
        )
    }
}

// MARK: - Extensions

extension DebugLog {
    func toRealmDebugLog() -> RealmDebugLog {
        let realm = RealmDebugLog()
        realm.id = id
        realm.level = level.rawValue
        realm.category = category
        realm.message = message
        realm.file = file
        realm.function = function
        realm.line = line
        realm.timestamp = timestamp

        if let metadata = metadata,
           let jsonData = try? JSONEncoder().encode(metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            realm.metadataJSON = jsonString
        }

        return realm
    }
}
