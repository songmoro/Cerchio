//
//  SettingsConstants.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import Foundation

enum SettingsConstants {
    enum Strings {
        // Section Titles
        static let generalSectionTitle = String(localized: .settingsSectionGeneral)
        static let dataSectionTitle = String(localized: .settingsSectionData)
        static let contactSectionTitle = String(localized: .settingsSectionContact)
        static let infoSectionTitle = String(localized: .settingsSectionInfo)

        // Row Titles
        static let languageRowTitle = String(localized: .settingsRowLanguage)
        static let resetDataRowTitle = String(localized: .settingsRowResetData)
        static let contactRowTitle = String(localized: .settingsRowContact)
        static let appVersionRowTitle = String(localized: .settingsRowAppVersion)

        // Contact Options
        static let instagramTitle = String(localized: .settingsContactInstagram)
        static let emailTitle = String(localized: .settingsContactEmail)

        // Alert Titles
        static let resetConfirmationTitle = String(localized: .settingsAlertResetDataTitle)
        static let resetConfirmationMessage = String(localized: .settingsAlertResetDataMessage)
        static let languageSelectionTitle = String(localized: .settingsAlertLanguageSelectionTitle)
        static let languageSelectionMessage = String(localized: .settingsAlertLanguageSelectionMessage)
        static let languageChangedTitle = String(localized: .settingsAlertLanguageChangedTitle)
        static let languageChangedMessage = String(localized: .settingsAlertLanguageChangedMessage)

        // Action Titles
        static let cancelAction = String(localized: .actionCancel)
        static let resetAction = String(localized: .actionReset)
        static let confirmAction = String(localized: .actionConfirm)
    }

    // MARK: - App Info

    static var appVersion: String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "Unknown"
        }
        return version
    }

    enum CellIdentifiers {
        static let defaultCell = "Cell"
        static let valueCell = "ValueCell"
    }
}
