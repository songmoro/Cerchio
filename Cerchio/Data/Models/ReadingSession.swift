//
//  ReadingSession.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import Foundation
import RealmSwift

nonisolated struct ReadingSession: Hashable, Sendable {
    let id: String
    let bookId: String
    let startTime: Date
    let endTime: Date?
    let durationSeconds: Int
    let targetMinutes: Int
    let status: SessionStatus
    let drawingData: DrawingData?
    let createdAt: Date

    enum SessionStatus: String, Codable, Sendable {
        case inProgress
        case completed
        case cancelled
    }
}

nonisolated struct DrawingData: Hashable, Codable, Sendable {
    let generatorType: String
    let seed: Int
    let instructions: [DrawingElement]
}

nonisolated struct DrawingElement: Hashable, Codable, Sendable {
    let type: ElementType
    let commands: [DrawingCommand]
    let style: DrawingStyle
    let timing: AnimationTiming

    enum ElementType: String, Codable, Sendable {
        case organicPath
        case geometricShape
        case wave
    }
}

nonisolated struct DrawingCommand: Hashable, Codable, Sendable {
    let type: CommandType
    let points: [Point]
    let controlPoints: [Point]?

    enum CommandType: String, Codable, Sendable {
        case move
        case line
        case curve
        case arc
    }
}

nonisolated struct Point: Hashable, Codable, Sendable {
    let x: Double
    let y: Double

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(_ cgPoint: CGPoint) {
        self.x = Double(cgPoint.x)
        self.y = Double(cgPoint.y)
    }

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

nonisolated struct DrawingStyle: Hashable, Codable, Sendable {
    let strokeColor: String
    let strokeWidth: Double
    let fillColor: String?
    let opacity: Double
}

nonisolated struct AnimationTiming: Hashable, Codable, Sendable {
    let delay: Double
    let duration: Double
    let easing: String
}

final class RealmReadingSession: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var bookId: String
    @Persisted var startTime: Date
    @Persisted var endTime: Date?
    @Persisted var durationSeconds: Int
    @Persisted var targetMinutes: Int
    @Persisted var status: String
    @Persisted var drawingGeneratorType: String?
    @Persisted var drawingSeed: Int
    @Persisted var drawingInstructionsJSON: String?
    @Persisted var createdAt: Date

    convenience init(
        id: String = UUID().uuidString,
        bookId: String,
        startTime: Date,
        targetMinutes: Int,
        status: ReadingSession.SessionStatus = .inProgress
    ) {
        self.init()
        self.id = id
        self.bookId = bookId
        self.startTime = startTime
        self.targetMinutes = targetMinutes
        self.status = status.rawValue
        self.durationSeconds = 0
        self.createdAt = Date()
        self.drawingSeed = 0
    }

    func toReadingSession() -> ReadingSession {
        var drawingData: DrawingData?
        if let generatorType = drawingGeneratorType,
           let jsonString = drawingInstructionsJSON,
           let jsonData = jsonString.data(using: .utf8),
           let instructions = try? JSONDecoder().decode([DrawingElement].self, from: jsonData) {
            drawingData = DrawingData(
                generatorType: generatorType,
                seed: drawingSeed,
                instructions: instructions
            )
        }

        return ReadingSession(
            id: id,
            bookId: bookId,
            startTime: startTime,
            endTime: endTime,
            durationSeconds: durationSeconds,
            targetMinutes: targetMinutes,
            status: ReadingSession.SessionStatus(rawValue: status) ?? .inProgress,
            drawingData: drawingData,
            createdAt: createdAt
        )
    }
}

extension ReadingSession {
    func toRealmReadingSession() -> RealmReadingSession {
        let realm = RealmReadingSession()
        realm.id = id
        realm.bookId = bookId
        realm.startTime = startTime
        realm.endTime = endTime
        realm.durationSeconds = durationSeconds
        realm.targetMinutes = targetMinutes
        realm.status = status.rawValue
        realm.createdAt = createdAt

        if let drawing = drawingData {
            realm.drawingGeneratorType = drawing.generatorType
            realm.drawingSeed = drawing.seed
            if let jsonData = try? JSONEncoder().encode(drawing.instructions),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                realm.drawingInstructionsJSON = jsonString
            }
        }

        return realm
    }
}
