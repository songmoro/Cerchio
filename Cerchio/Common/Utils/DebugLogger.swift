//
//  DebugLogger.swift
//  Cerchio
//
//  Created by 송재훈 on 10/7/25.
//

import Foundation
import RxSwift

final class DebugLogger {
    static let shared = DebugLogger()

    private let repository: DebugLogRepositoryProtocol
    private let disposeBag = DisposeBag()
    private let logQueue = DispatchQueue(label: "debugLogger.queue", qos: .utility)

    private init() {
        do {
            self.repository = try DebugLogRepository()
        } catch {
            fatalError("Failed to initialize DebugLogRepository: \(error)")
        }
    }

    func debug(
        _ message: String,
        category: String = "General",
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func info(
        _ message: String,
        category: String = "General",
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func warning(
        _ message: String,
        category: String = "General",
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    func error(
        _ message: String,
        category: String = "General",
        metadata: [String: String]? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message: message, category: category, metadata: metadata, file: file, function: function, line: line)
    }

    private func log(
        level: LogLevel,
        message: String,
        category: String,
        metadata: [String: String]?,
        file: String,
        function: String,
        line: Int
    ) {
        logQueue.async { [weak self] in
            guard let self = self else { return }

            let fileName = (file as NSString).lastPathComponent
            let debugLog = DebugLog(
                level: level,
                category: category,
                message: message,
                file: fileName,
                function: function,
                line: line,
                metadata: metadata
            )

            _ = DateFormatter.localizedString(from: debugLog.timestamp, dateStyle: .none, timeStyle: .medium)
            _ = "\(level.emoji) [\(category)] \(fileName):\(line) - \(message)"

            if let metadata = metadata, !metadata.isEmpty {
                _ = metadata
            }

            DispatchQueue.main.async {
                self.repository.saveLog(debugLog)
                    .observe(on: MainScheduler.instance)
                    .subscribe(
                        onNext: { _ in },
                        onError: { error in
                            print(" Failed to save log to Realm: \(error)")
                        }
                    )
                    .disposed(by: self.disposeBag)
            }
        }
    }

    func getAllLogs() -> Observable<[DebugLog]> {
        return repository.getAllLogs()
            .observe(on: MainScheduler.instance)
    }

    func getLogs(category: String) -> Observable<[DebugLog]> {
        return repository.getLogs(category: category)
            .observe(on: MainScheduler.instance)
    }

    func getLogs(level: LogLevel) -> Observable<[DebugLog]> {
        return repository.getLogs(level: level)
            .observe(on: MainScheduler.instance)
    }

    func getLogs(since date: Date) -> Observable<[DebugLog]> {
        return repository.getLogs(since: date)
            .observe(on: MainScheduler.instance)
    }

    func deleteOldLogs(olderThan date: Date) -> Observable<Void> {
        return repository.deleteOldLogs(olderThan: date)
            .observe(on: MainScheduler.instance)
    }

    func deleteAllLogs() -> Observable<Void> {
        return repository.deleteAllLogs()
            .observe(on: MainScheduler.instance)
    }

    func deleteLogsOlderThan(days: Int) -> Observable<Void> {
        guard let date = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return Observable.error(NSError(domain: "DebugLogger", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid date calculation"]))
        }
        return deleteOldLogs(olderThan: date)
    }

    func printAllLogs() {
        getAllLogs()
            .subscribe(onNext: { logs in
                for log in logs {
                    _ = DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .medium)
                    if let metadata = log.metadata, !metadata.isEmpty {
                        _ = metadata
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    func printLogs(category: String) {
        getLogs(category: category)
            .subscribe(onNext: { logs in
                for log in logs {
                    _ = DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .medium)
                    if let metadata = log.metadata, !metadata.isEmpty {
                        _ = metadata
                    }
                }
            })
            .disposed(by: disposeBag)
    }
}
