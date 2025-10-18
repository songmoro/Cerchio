//
//  BookDetailService.swift
//  Cerchio
//
//  Created by 송재훈 on 10/2/25.
//

import UIKit
import RxSwift
import RealmSwift

final class BookDetailService {
    let serviceFactory: ServiceFactory

    init(serviceFactory: ServiceFactory) {
        self.serviceFactory = serviceFactory
    }

    // MARK: - Photo Operations

    /// 사진 메타데이터와 이미지를 비동기로 로드
    /// - 메인 스레드: Realm 접근, 경로 추출
    /// - 백그라운드: 이미지 파일 로딩 (병렬)
    func loadPhotosWithImages(bookId: String) async throws -> [UIImage] {
        // 1. 메인 스레드에서 Realm 접근하여 경로만 추출
        let imagePaths = try await MainActor.run {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)

            // 메인 스레드에서 경로만 추출 (가벼운 작업)
            return Array(photos.map { $0.localImagePath })
        }

        // 2. 백그라운드에서 이미지 로딩 (병렬 처리)
        return await loadImagesInBackground(from: imagePaths)
    }

    /// Realm 메타데이터만 로드 (Observable)
    func loadPhotos(bookId: String) -> Observable<[RealmPhoto]> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let photos = realm.objects(RealmPhoto.self)
                    .filter("bookId == %@", bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                observer.onNext(Array(photos))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    /// 이미지 경로 목록에서 이미지 로드 (백그라운드 병렬 처리)
    func loadPhotoImages(photos: [RealmPhoto]) async -> [UIImage] {
        let imagePaths = photos.map { $0.localImagePath }
        return await loadImagesInBackground(from: imagePaths)
    }

    /// 백그라운드에서 이미지 병렬 로딩
    func loadImagesInBackground(from paths: [String]) async -> [UIImage] {
        await withTaskGroup(of: (index: Int, image: UIImage?).self) { group in
            for (index, path) in paths.enumerated() {
                group.addTask {
                    // 백그라운드에서 이미지 로드
                    let image = await ImageStorageManager.shared.loadImage(fromPath: path)
                    return (index, image)
                }
            }

            // 원본 순서 유지를 위해 index와 함께 저장
            var indexedImages: [(index: Int, image: UIImage)] = []
            for await result in group {
                if let image = result.image {
                    indexedImages.append((result.index, image))
                }
            }

            // 원본 순서대로 정렬하여 반환
            return indexedImages
                .sorted { $0.index < $1.index }
                .map { $0.image }
        }
    }

    // MARK: - Quote Operations

    func loadQuotes(bookId: String) -> Observable<[RealmQuote]> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let quotes = realm.objects(RealmQuote.self)
                    .filter("bookId == %@", bookId)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                observer.onNext(Array(quotes))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    // MARK: - Tag Operations

    func loadTags(bookId: String) -> Observable<[RealmTag]> {
        let tagRepository = serviceFactory.createTagRepository()
        return tagRepository.getTags(for: bookId)
    }

    // MARK: - Photo Save

    func savePhoto(_ image: UIImage, bookId: String) -> Observable<RealmPhoto> {
        return Observable.create { observer in
            // 로컬 저장
            let imageName = ImageStorageManager.shared.generateUniqueImageName(for: bookId)
            guard let localPath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
                observer.onError(NSError(domain: "ImageSaveError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save image locally"]))
                return Disposables.create()
            }

            // Realm 저장
            let realmPhoto = RealmPhoto(bookId: bookId, localImagePath: localPath)

            do {
                let realm = try Realm()
                try realm.write {
                    realm.add(realmPhoto)
                }
                observer.onNext(realmPhoto)
                observer.onCompleted()
            } catch {
                // 실패 시 로컬 이미지 삭제
                _ = ImageStorageManager.shared.deleteImage(atPath: localPath)
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    // MARK: - Reading Statistics

    func calculateReadingStatistics(for bookId: String) -> Observable<ReadingStatistics> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let sessions = realm.objects(RealmReadingSession.self)
                    .filter("bookId == %@ AND status == %@", bookId, ReadingSession.SessionStatus.completed.rawValue)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                let now = Date()
                let calendar = Calendar.current

                // 오늘 시작 시간 (00:00:00)
                let todayStart = calendar.startOfDay(for: now)

                // 이번 주 시작 시간 (월요일 00:00:00)
                let weekStart = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!

                // 이번 달 시작 시간 (1일 00:00:00)
                let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

                var totalTime = 0
                var todayTime = 0
                var weekTime = 0
                var monthTime = 0

                var todayCount = 0
                var weekCount = 0
                var monthCount = 0

                for session in sessions {
                    totalTime += session.durationSeconds

                    if session.createdAt >= todayStart {
                        todayTime += session.durationSeconds
                        todayCount += 1
                    }

                    if session.createdAt >= weekStart {
                        weekTime += session.durationSeconds
                        weekCount += 1
                    }

                    if session.createdAt >= monthStart {
                        monthTime += session.durationSeconds
                        monthCount += 1
                    }
                }

                let statistics = ReadingStatistics(
                    totalTime: totalTime,
                    totalSessions: sessions.count,
                    todayTime: todayTime,
                    todaySessions: todayCount,
                    weekTime: weekTime,
                    weekSessions: weekCount,
                    monthTime: monthTime,
                    monthSessions: monthCount
                )

                observer.onNext(statistics)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    func loadReadingSessions(for bookId: String) -> Observable<[RealmReadingSession]> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let sessions = realm.objects(RealmReadingSession.self)
                    .filter("bookId == %@ AND status == %@", bookId, ReadingSession.SessionStatus.completed.rawValue)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                observer.onNext(Array(sessions))
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    // MARK: - Reading Chart Data

    func loadReadingChartData(for bookId: String, period: ReadingStatisticsPeriod) -> Observable<ReadingChartData> {
        return Observable.create { observer in
            do {
                let realm = try Realm()
                let calendar = Calendar.current
                let now = Date()

                let sessions = realm.objects(RealmReadingSession.self)
                    .filter("bookId == %@ AND status == %@", bookId, ReadingSession.SessionStatus.completed.rawValue)
                    .sorted(byKeyPath: "createdAt", ascending: false)

                let chartData: ReadingChartData

                switch period {
                case .today:
                    chartData = self.createHourlyChartData(from: Array(sessions), period: period, calendar: calendar, now: now)
                case .week:
                    chartData = self.createWeeklyChartData(from: Array(sessions), calendar: calendar, now: now)
                case .month:
                    chartData = self.createMonthlyChartData(from: Array(sessions), calendar: calendar, now: now)
                case .year:
                    chartData = self.createYearlyChartData(from: Array(sessions), calendar: calendar, now: now)
                }

                observer.onNext(chartData)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }

            return Disposables.create()
        }
    }

    private func createHourlyChartData(from sessions: [RealmReadingSession], period: ReadingStatisticsPeriod, calendar: Calendar, now: Date) -> ReadingChartData {
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        var filteredSessions = sessions
        if period == .today {
            filteredSessions = sessions.filter { $0.startTime >= todayStart && $0.startTime < todayEnd }
        }

        var hourlyData: [Int: [(startMinute: Int, endMinute: Int)]] = [:]

        for session in filteredSessions {
            let hour = calendar.component(.hour, from: session.startTime)
            let minute = calendar.component(.minute, from: session.startTime)
            let durationMinutes = session.durationSeconds / 60

            let startMinute = minute
            let endMinute = min(minute + durationMinutes, 60)

            if hourlyData[hour] == nil {
                hourlyData[hour] = []
            }
            hourlyData[hour]?.append((startMinute, endMinute))
        }

        var dataPoints: [ReadingChartData.DataPoint] = []

        for hour in 0..<24 {
            if let readings = hourlyData[hour], !readings.isEmpty {
                let minStart = readings.map { $0.startMinute }.min() ?? 0
                let maxEnd = readings.map { $0.endMinute }.max() ?? 0

                if maxEnd > minStart {
                    let xValue = self.formatHourLabel(hour)
                    let id = "\(hour)"
                    dataPoints.append(ReadingChartData.DataPoint(
                        id: id,
                        xValue: xValue,
                        startMinute: minStart,
                        endMinute: maxEnd
                    ))
                }
            }
        }

        let totalMinutes = filteredSessions.reduce(0) { $0 + ($1.durationSeconds / 60) }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let dateRange = period == .today ? dateFormatter.string(from: now) : "전체"

        return ReadingChartData(
            period: period,
            dataPoints: dataPoints,
            totalMinutes: totalMinutes,
            sessionCount: filteredSessions.count,
            dateRange: dateRange
        )
    }

    private func createWeeklyChartData(from sessions: [RealmReadingSession], calendar: Calendar, now: Date) -> ReadingChartData {
        let weekStart = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
        let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!

        let filteredSessions = sessions.filter { $0.startTime >= weekStart && $0.startTime < weekEnd }

        var dailyMinutes: [Int: Int] = [:]

        for session in filteredSessions {
            let weekday = calendar.component(.weekday, from: session.startTime)
            let minutes = session.durationSeconds / 60
            dailyMinutes[weekday, default: 0] += minutes
        }

        var dataPoints: [ReadingChartData.DataPoint] = []

        let weekdaySymbols = ["일", "월", "화", "수", "목", "금", "토"]

        for weekday in 1...7 {
            if let minutes = dailyMinutes[weekday], minutes > 0 {
                let xValue = weekdaySymbols[weekday - 1]
                dataPoints.append(ReadingChartData.DataPoint(
                    id: "\(weekday)",
                    xValue: xValue,
                    startMinute: 0,
                    endMinute: minutes
                ))
            }
        }

        let totalMinutes = filteredSessions.reduce(0) { $0 + ($1.durationSeconds / 60) }

        return ReadingChartData(
            period: .week,
            dataPoints: dataPoints,
            totalMinutes: totalMinutes,
            sessionCount: filteredSessions.count,
            dateRange: "이번 주"
        )
    }

    private func createMonthlyChartData(from sessions: [RealmReadingSession], calendar: Calendar, now: Date) -> ReadingChartData {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!

        let filteredSessions = sessions.filter { $0.startTime >= monthStart && $0.startTime < monthEnd }

        var dailyMinutes: [Int: Int] = [:]

        for session in filteredSessions {
            let day = calendar.component(.day, from: session.startTime)
            let minutes = session.durationSeconds / 60
            dailyMinutes[day, default: 0] += minutes
        }

        var dataPoints: [ReadingChartData.DataPoint] = []

        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        for day in 1...daysInMonth {
            if let minutes = dailyMinutes[day], minutes > 0 {
                dataPoints.append(ReadingChartData.DataPoint(
                    id: "\(day)",
                    xValue: "\(day)",
                    startMinute: 0,
                    endMinute: minutes
                ))
            }
        }

        let totalMinutes = filteredSessions.reduce(0) { $0 + ($1.durationSeconds / 60) }

        return ReadingChartData(
            period: .month,
            dataPoints: dataPoints,
            totalMinutes: totalMinutes,
            sessionCount: filteredSessions.count,
            dateRange: "이번 달"
        )
    }

    private func createYearlyChartData(from sessions: [RealmReadingSession], calendar: Calendar, now: Date) -> ReadingChartData {
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: now))!
        let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart)!

        let filteredSessions = sessions.filter { $0.startTime >= yearStart && $0.startTime < yearEnd }

        var monthlyMinutes: [Int: Int] = [:]

        for session in filteredSessions {
            let month = calendar.component(.month, from: session.startTime)
            let minutes = session.durationSeconds / 60
            monthlyMinutes[month, default: 0] += minutes
        }

        var dataPoints: [ReadingChartData.DataPoint] = []

        for month in 1...12 {
            if let minutes = monthlyMinutes[month], minutes > 0 {
                dataPoints.append(ReadingChartData.DataPoint(
                    id: "\(month)",
                    xValue: "\(month)월",
                    startMinute: 0,
                    endMinute: minutes
                ))
            }
        }

        let totalMinutes = filteredSessions.reduce(0) { $0 + ($1.durationSeconds / 60) }

        return ReadingChartData(
            period: .year,
            dataPoints: dataPoints,
            totalMinutes: totalMinutes,
            sessionCount: filteredSessions.count,
            dateRange: "올해"
        )
    }

    private func formatHourLabel(_ hour: Int) -> String {
        switch hour {
        case 0: return "12 AM"
        case 6: return "6"
        case 12: return "12 PM"
        case 18: return "6"
        default: return ""
        }
    }
}
