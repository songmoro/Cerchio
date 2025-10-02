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
        case data

        var title: String? {
            switch self {
            case .data:
                return SettingsConstants.Strings.dataSectionTitle
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

    // MARK: - Setup

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
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }

        switch sectionType {
        case .data:
            return DataRow.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return tableView.dequeueReusableCell(withIdentifier: SettingsConstants.CellIdentifiers.defaultCell, for: indexPath)
        }

        switch sectionType {
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

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let sectionType = Section(rawValue: indexPath.section) else { return }

        switch sectionType {
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