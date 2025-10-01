//
//  SettingsConstants.swift
//  Cerchio
//
//  Created by Claude on 10/1/25.
//

import Foundation

enum SettingsConstants {
    enum Strings {
        // Section Titles
        static let generalSectionTitle = "일반"
        static let dataSectionTitle = "데이터"

        // Row Titles
        static let languageRowTitle = "언어"
        static let resetDataRowTitle = "모든 데이터 초기화"

        // Alert Titles
        static let resetConfirmationTitle = "모든 데이터 초기화"
        static let resetConfirmationMessage = "모든 책, 인용구, 사진이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다."
        static let languageSelectionTitle = "언어 선택"
        static let languageSelectionMessage = "앱의 언어를 선택하세요.\n변경 사항을 적용하려면 앱을 재시작해야 합니다."
        static let languageChangedTitle = "언어 변경됨"
        static let languageChangedMessage = "앱을 재시작하면 변경 사항이 적용됩니다."

        // Action Titles
        static let cancelAction = "취소"
        static let resetAction = "초기화"
        static let confirmAction = "확인"
    }

    enum CellIdentifiers {
        static let defaultCell = "Cell"
        static let valueCell = "ValueCell"
    }
}
