//
//  ContactViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/20/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ContactViewController: UIViewController {

    // MARK: - 프로퍼티

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let disposeBag = DisposeBag()

    var instagramURL: String?
    var emailAddress: String?

    private enum ContactRow: Int, CaseIterable {
        case instagram
        case email

        var title: String {
            switch self {
            case .instagram:
                return SettingsConstants.Strings.instagramTitle
            case .email:
                return SettingsConstants.Strings.emailTitle
            }
        }

        var icon: String {
            switch self {
            case .instagram:
                return "arrow.up.forward.app"
            case .email:
                return "envelope"
            }
        }
    }

    // MARK: - 생명주기

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - 설정

    private func setupUI() {
        title = SettingsConstants.Strings.contactRowTitle
        view.backgroundColor = .systemGroupedBackground

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")
        tableView.backgroundColor = .clear

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }

    // MARK: - 내부 메서드

    private func openInstagram() {
        guard let urlString = instagramURL,
              let url = URL(string: urlString) else { return }

        HapticFeedbackManager.shared.impact()
        UIApplication.shared.open(url)
    }

    private func openEmail() {
        guard let email = emailAddress,
              let url = URL(string: "mailto:\(email)") else { return }

        HapticFeedbackManager.shared.impact()
        UIApplication.shared.open(url)
    }
}

// MARK: - UITableViewDataSource

extension ContactViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ContactRow.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)

        guard let rowType = ContactRow(rawValue: indexPath.row) else {
            return cell
        }

        var config = cell.defaultContentConfiguration()

        switch rowType {
        case .instagram:
            config.text = rowType.title
        case .email:
            config.text = emailAddress ?? rowType.title
        }

        config.image = UIImage(systemName: rowType.icon)
        config.imageProperties.tintColor = .tintColor

        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let rowType = ContactRow(rawValue: indexPath.row) else { return }

        switch rowType {
        case .instagram:
            openInstagram()
        case .email:
            openEmail()
        }
    }
}
