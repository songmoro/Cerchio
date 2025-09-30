//
//  SettingsViewController.swift
//  Cerchio
//
//  Created by Claude on 9/30/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class SettingsViewController: BaseViewController<SettingsReactor> {

    // MARK: - Properties

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case general
        case data

        var title: String? {
            switch self {
            case .general:
                return "일반"
            case .data:
                return "데이터"
            }
        }
    }

    private enum GeneralRow: Int, CaseIterable {
        case language

        var title: String {
            switch self {
            case .language:
                return "언어"
            }
        }
    }

    private enum DataRow: Int, CaseIterable {
        case resetData

        var title: String {
            switch self {
            case .resetData:
                return "모든 데이터 초기화"
            }
        }

        var textColor: UIColor {
            switch self {
            case .resetData:
                return .systemRed
            }
        }
    }

    // MARK: - Setup

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        // Value1 스타일로 detail text 표시
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ValueCell")
        tableView.backgroundColor = .clear

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func bind(reactor: SettingsReactor) {
        // Action

        // State
        reactor.state
            .map { $0.isResetting }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isResetting in
                self?.handleResetState(isResetting)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.currentLanguage }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
                self?.showLanguageChangedAlert()
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods

    private func handleResetState(_ isResetting: Bool) {
        if isResetting {
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
        }
    }

    private func showLoadingIndicator() {
        // TODO: 로딩 인디케이터 표시
    }

    private func hideLoadingIndicator() {
        // TODO: 로딩 인디케이터 숨김
    }

    private func showResetConfirmationAlert() {
        let alert = UIAlertController(
            title: "모든 데이터 초기화",
            message: "모든 책, 인용구, 사진이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.",
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: "취소", style: .cancel)

        let resetAction = UIAlertAction(title: "초기화", style: .destructive) { [weak self] _ in
            self?.performReset()
        }

        alert.addAction(cancelAction)
        alert.addAction(resetAction)

        present(alert, animated: true)
    }

    private func performReset() {
        reactor?.action.onNext(.resetAllData)
    }

    private func showLanguageSelection() {
        let alert = UIAlertController(
            title: "언어 선택",
            message: "앱의 언어를 선택하세요.\n변경 사항을 적용하려면 앱을 재시작해야 합니다.",
            preferredStyle: .actionSheet
        )

        for language in AppLanguage.allCases {
            let action = UIAlertAction(title: language.displayName, style: .default) { [weak self] _ in
                self?.changeLanguage(to: language)
            }

            // 현재 선택된 언어 표시
            if language == LanguageManager.shared.currentLanguage {
                action.setValue(true, forKey: "checked")
            }

            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))

        // iPad 지원
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) {
                popover.sourceRect = cell.frame
            }
        }

        present(alert, animated: true)
    }

    private func changeLanguage(to language: AppLanguage) {
        reactor?.action.onNext(.changeLanguage(language))
    }

    private func showLanguageChangedAlert() {
        let alert = UIAlertController(
            title: "언어 변경됨",
            message: "앱을 재시작하면 변경 사항이 적용됩니다.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "확인", style: .default))

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .general:
            return GeneralRow.allCases.count
        case .data:
            return DataRow.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        }

        switch sectionType {
        case .general:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: "ValueCell")
            if let rowType = GeneralRow(rawValue: indexPath.row) {
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator

                // 현재 선택된 언어 표시
                if rowType == .language {
                    let currentLanguage = LanguageManager.shared.currentLanguage
                    cell.detailTextLabel?.text = currentLanguage.displayName
                    cell.detailTextLabel?.textColor = .secondaryLabel
                }
            }
            return cell

        case .data:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            if let rowType = DataRow(rawValue: indexPath.row) {
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = rowType.textColor
                cell.selectionStyle = .default
                cell.accessoryType = .none
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        return sectionType.title
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .general:
            if let rowType = GeneralRow(rawValue: indexPath.row) {
                switch rowType {
                case .language:
                    showLanguageSelection()
                }
            }

        case .data:
            if let rowType = DataRow(rawValue: indexPath.row) {
                switch rowType {
                case .resetData:
                    showResetConfirmationAlert()
                }
            }
        }
    }
}