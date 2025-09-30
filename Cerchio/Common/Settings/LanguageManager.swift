//
//  LanguageManager.swift
//  Cerchio
//
//  Created by Claude on 9/30/25.
//

import Foundation
import RealmSwift

enum AppLanguage: String, CaseIterable {
    case korean = "ko"
    case english = "en"

    var displayName: String {
        switch self {
        case .korean:
            return "한국어"
        case .english:
            return "English"
        }
    }

    var localeIdentifier: String {
        return rawValue
    }
}

// Realm 모델
class RealmAppSettings: Object {
    @Persisted(primaryKey: true) var id: String = "appSettings"
    @Persisted var languageCode: String = "ko"

    convenience init(languageCode: String) {
        self.init()
        self.languageCode = languageCode
    }
}

final class LanguageManager {
    static let shared = LanguageManager()

    private init() {}

    var currentLanguage: AppLanguage {
        do {
            let realm = try Realm()
            if let settings = realm.object(ofType: RealmAppSettings.self, forPrimaryKey: "appSettings"),
               let language = AppLanguage(rawValue: settings.languageCode) {
                return language
            }
        } catch {
            print("❌ Failed to load language from Realm: \(error)")
        }
        return .korean // 기본값
    }

    func setLanguage(_ language: AppLanguage) {
        do {
            let realm = try Realm()
            try realm.write {
                let settings = RealmAppSettings(languageCode: language.rawValue)
                realm.add(settings, update: .modified)
            }

            // AppleLanguages 설정
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()

            // Bundle 재설정을 위한 notification
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        } catch {
            print("❌ Failed to save language to Realm: \(error)")
        }
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("LanguageChanged")
}