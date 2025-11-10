//
//  SettingsViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class SettingsViewController: BaseViewController<SettingsReactor> {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private enum Section: Int, CaseIterable {
        case general
        case contact
        case info
        case data

        var title: String? {
            switch self {
            case .general:
                return SettingsConstants.Strings.generalSectionTitle
            case .contact:
                return SettingsConstants.Strings.contactSectionTitle
            case .info:
                return SettingsConstants.Strings.infoSectionTitle
            case .data:
                return SettingsConstants.Strings.dataSectionTitle
            }
        }
    }

    private enum GeneralRow: Int, CaseIterable {
        case language

        var title: String {
            switch self {
            case .language:
                return SettingsConstants.Strings.languageRowTitle
            }
        }
    }

    private enum ContactRow: Int, CaseIterable {
        case contact

        var title: String {
            switch self {
            case .contact:
                return SettingsConstants.Strings.contactRowTitle
            }
        }
    }

    private enum InfoRow: Int, CaseIterable {
        case appVersion

        var title: String {
            switch self {
            case .appVersion:
                return SettingsConstants.Strings.appVersionRowTitle
            }
        }
    }

    private enum DataRow: Int, CaseIterable {
        case resetData

        var title: String {
            switch self {
            case .resetData:
                return SettingsConstants.Strings.resetDataRowTitle
            }
        }

        var textColor: UIColor {
            switch self {
            case .resetData:
                return .systemRed
            }
        }
    }

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SettingsConstants.CellIdentifiers.defaultCell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: SettingsConstants.CellIdentifiers.valueCell)
        tableView.backgroundColor = .clear

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func bind(reactor: SettingsReactor) {

        reactor.state
            .map { $0.isResetting }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isResetting in
                self?.handleResetState(isResetting)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.resetCompleted }
            .distinctUntilChanged()
            .filter { $0 == true }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.handleResetCompleted()
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.currentLanguage }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: disposeBag)
    }

    private func handleResetState(_ isResetting: Bool) {
        if isResetting {
            showLoadingIndicator()
        } else {
            hideLoadingIndicator()
        }
    }

    private func showLoadingIndicator() {
    }

    private func hideLoadingIndicator() {
    }

    private func showResetConfirmationAlert() {
        let alert = UIAlertController(
            title: SettingsConstants.Strings.resetConfirmationTitle,
            message: SettingsConstants.Strings.resetConfirmationMessage,
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: SettingsConstants.Strings.cancelAction, style: .cancel)

        let resetAction = UIAlertAction(title: SettingsConstants.Strings.resetAction, style: .destructive) { [weak self] _ in
            self?.performReset()
        }

        alert.addAction(cancelAction)
        alert.addAction(resetAction)

        present(alert, animated: true)
    }

    private func performReset() {
        reactor?.action.onNext(.resetAllData)
    }

    private func handleResetCompleted() {
        NotificationCenter.default.post(name: .dataDidReset, object: nil)
    }

    private func showLanguageSelectionAlert() {
        let alert = UIAlertController(
            title: SettingsConstants.Strings.languageSelectionTitle,
            message: SettingsConstants.Strings.languageSelectionMessage,
            preferredStyle: .actionSheet
        )

        for language in AppLanguage.allCases {
            let action = UIAlertAction(title: language.displayName, style: .default) { [weak self] _ in
                self?.changeLanguage(to: language)
            }
            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: SettingsConstants.Strings.cancelAction, style: .cancel)
        alert.addAction(cancelAction)

        present(alert, animated: true)
    }

    private func changeLanguage(to language: AppLanguage) {
        reactor?.action.onNext(.changeLanguage(language))

        let alert = UIAlertController(
            title: SettingsConstants.Strings.languageChangedTitle,
            message: SettingsConstants.Strings.languageChangedMessage,
            preferredStyle: .alert
        )

        let confirmAction = UIAlertAction(title: SettingsConstants.Strings.confirmAction, style: .default)

        alert.addAction(confirmAction)
        present(alert, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .general:
            return GeneralRow.allCases.count
        case .contact:
            return ContactRow.allCases.count
        case .info:
            return InfoRow.allCases.count
        case .data:
            return DataRow.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return tableView.dequeueReusableCell(withIdentifier: SettingsConstants.CellIdentifiers.defaultCell, for: indexPath)
        }

        switch sectionType {
        case .general:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            if let rowType = GeneralRow(rawValue: indexPath.row) {
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.text = reactor?.currentState.currentLanguage.displayName
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
            }
            return cell
        case .contact:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsConstants.CellIdentifiers.defaultCell, for: indexPath)
            if let rowType = ContactRow(rawValue: indexPath.row) {
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.selectionStyle = .default
                cell.accessoryType = .disclosureIndicator
            }
            return cell
        case .info:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            if let rowType = InfoRow(rawValue: indexPath.row) {
                cell.textLabel?.text = rowType.title
                cell.textLabel?.textColor = .label
                cell.detailTextLabel?.text = SettingsConstants.appVersion
                cell.detailTextLabel?.textColor = .secondaryLabel
                cell.selectionStyle = .none
                cell.accessoryType = .none
            }
            return cell
        case .data:
            let cell = tableView.dequeueReusableCell(withIdentifier: SettingsConstants.CellIdentifiers.defaultCell, for: indexPath)
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

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
        case .general:
            if let rowType = GeneralRow(rawValue: indexPath.row) {
                switch rowType {
                case .language:
                    showLanguageSelectionAlert()
                }
            }
        case .contact:
            if let rowType = ContactRow(rawValue: indexPath.row) {
                switch rowType {
                case .contact:
                    HapticFeedbackManager.shared.impact()
                    (coordinator as? SettingsCoordinator)?.showContactViewController()
                }
            }
        case .info:
            break
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
