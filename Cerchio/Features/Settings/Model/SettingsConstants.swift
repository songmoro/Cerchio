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

        // Row Titles
        static let languageRowTitle = String(localized: .settingsRowLanguage)
        static let resetDataRowTitle = String(localized: .settingsRowResetData)

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

    enum CellIdentifiers {
        static let defaultCell = "Cell"
        static let valueCell = "ValueCell"
    }
}
