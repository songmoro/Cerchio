//
//  DebugLogger.swift
//  Cerchio
//
//  Created by 송재훈 on 10/7/25.
//

import Foundation
import RxSwift

/// Singleton logger that persists logs to Realm for debugging across app restarts
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

    // MARK: - Public Logging Methods

    /// Log a debug message
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

    /// Log an info message
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

    /// Log a warning message
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

    /// Log an error message
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

    // MARK: - Private Methods

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

            // Console output
            let timestamp = DateFormatter.localizedString(from: debugLog.timestamp, dateStyle: .none, timeStyle: .medium)
            let consoleMessage = "\(level.emoji) [\(timestamp)] [\(category)] \(fileName):\(line) - \(message)"
            print(consoleMessage)

            if let metadata = metadata, !metadata.isEmpty {
                print("   Metadata: \(metadata)")
            }

            // Save to Realm on main thread
            DispatchQueue.main.async {
                self.repository.saveLog(debugLog)
                    .observe(on: MainScheduler.instance)
                    .subscribe(
                        onNext: { _ in },
                        onError: { error in
                            print("❌ Failed to save log to Realm: \(error)")
                        }
                    )
                    .disposed(by: self.disposeBag)
            }
        }
    }

    // MARK: - Log Retrieval Methods

    /// Get all logs sorted by timestamp (newest first)
    func getAllLogs() -> Observable<[DebugLog]> {
        return repository.getAllLogs()
            .observe(on: MainScheduler.instance)
    }

    /// Get logs for a specific category
    func getLogs(category: String) -> Observable<[DebugLog]> {
        return repository.getLogs(category: category)
            .observe(on: MainScheduler.instance)
    }

    /// Get logs by level
    func getLogs(level: LogLevel) -> Observable<[DebugLog]> {
        return repository.getLogs(level: level)
            .observe(on: MainScheduler.instance)
    }

    /// Get logs since a specific date
    func getLogs(since date: Date) -> Observable<[DebugLog]> {
        return repository.getLogs(since: date)
            .observe(on: MainScheduler.instance)
    }

    // MARK: - Log Management Methods

    /// Delete logs older than the specified date
    func deleteOldLogs(olderThan date: Date) -> Observable<Void> {
        return repository.deleteOldLogs(olderThan: date)
            .observe(on: MainScheduler.instance)
    }

    /// Delete all logs
    func deleteAllLogs() -> Observable<Void> {
        return repository.deleteAllLogs()
            .observe(on: MainScheduler.instance)
    }

    /// Delete logs older than specified number of days
    func deleteLogsOlderThan(days: Int) -> Observable<Void> {
        guard let date = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return Observable.error(NSError(domain: "DebugLogger", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid date calculation"]))
        }
        return deleteOldLogs(olderThan: date)
    }

    // MARK: - Convenience Methods

    /// Print all logs to console
    func printAllLogs() {
        getAllLogs()
            .subscribe(onNext: { logs in
                print("\n========== DEBUG LOGS ==========")
                for log in logs {
                    let timestamp = DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .medium)
                    print("\(log.level.emoji) [\(timestamp)] [\(log.category)] \(log.file):\(log.line)")
                    print("   \(log.message)")
                    if let metadata = log.metadata, !metadata.isEmpty {
                        print("   Metadata: \(metadata)")
                    }
                }
                print("================================\n")
            })
            .disposed(by: disposeBag)
    }

    /// Print logs for a specific category
    func printLogs(category: String) {
        getLogs(category: category)
            .subscribe(onNext: { logs in
                print("\n========== [\(category)] LOGS ==========")
                for log in logs {
                    let timestamp = DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .medium)
                    print("\(log.level.emoji) [\(timestamp)] \(log.file):\(log.line)")
                    print("   \(log.message)")
                    if let metadata = log.metadata, !metadata.isEmpty {
                        print("   Metadata: \(metadata)")
                    }
                }
                print("====================================\n")
            })
            .disposed(by: disposeBag)
    }
}
