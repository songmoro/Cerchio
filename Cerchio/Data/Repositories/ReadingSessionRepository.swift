//
//  ReadingSessionRepository.swift
//  Cerchio
//
//  Created by Claude on 10/3/25.
//

import Foundation
import RealmSwift
import RxSwift

protocol ReadingSessionRepositoryProtocol {
    func getAllSessions() -> Observable<[RealmReadingSession]>
    func getSessionsByBookId(_ bookId: String) -> Observable<[RealmReadingSession]>
    func getActiveSession() -> Observable<RealmReadingSession?>
    func saveSession(_ session: RealmReadingSession) -> Observable<RealmReadingSession>
    func updateSession(_ session: RealmReadingSession) -> Observable<RealmReadingSession>
    func deleteSession(_ session: RealmReadingSession) -> Observable<Void>
    func completeSession(sessionId: String, endTime: Date, drawingData: DrawingData?) -> Observable<RealmReadingSession>
}

final class ReadingSessionRepository: BaseRepository<RealmReadingSession>, ReadingSessionRepositoryProtocol {

    func getAllSessions() -> Observable<[RealmReadingSession]> {
        return fetch()
    }

    func getSessionsByBookId(_ bookId: String) -> Observable<[RealmReadingSession]> {
        return filterAndSort(
            "bookId == %@",
            sortBy: "startTime",
            ascending: false,
            bookId
        )
    }

    func getActiveSession() -> Observable<RealmReadingSession?> {
        return performOnMainThread {
            self.realm.objects(RealmReadingSession.self)
                .filter("status == %@", ReadingSession.SessionStatus.inProgress.rawValue)
                .first
        }
    }

    func saveSession(_ session: RealmReadingSession) -> Observable<RealmReadingSession> {
        return save(session)
    }

    func updateSession(_ session: RealmReadingSession) -> Observable<RealmReadingSession> {
        return update(session)
    }

    func deleteSession(_ session: RealmReadingSession) -> Observable<Void> {
        return delete(session)
    }

    func completeSession(sessionId: String, endTime: Date, drawingData: DrawingData?) -> Observable<RealmReadingSession> {
        return performWriteTransaction {
            guard let session = self.realm.object(ofType: RealmReadingSession.self, forPrimaryKey: sessionId) else {
                throw RepositoryError.objectNotFound
            }

            session.endTime = endTime
            session.status = ReadingSession.SessionStatus.completed.rawValue

            let duration = Int(endTime.timeIntervalSince(session.startTime) / 60)
            session.durationMinutes = duration

            if let drawing = drawingData {
                session.drawingGeneratorType = drawing.generatorType
                session.drawingSeed = drawing.seed
                if let jsonData = try? JSONEncoder().encode(drawing.instructions),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    session.drawingInstructionsJSON = jsonString
                }
            }

            return session
        }
    }
}
