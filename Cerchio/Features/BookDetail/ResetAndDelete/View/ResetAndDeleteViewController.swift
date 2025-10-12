//
//  ResetAndDeleteViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import SnapKit
import ReactorKit
import RxCocoa

final class ResetAndDeleteViewController: BaseViewController<ResetAndDeleteReactor> {

    // MARK: - UI Components

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tableView
    }()

    private enum ResetOption: Int, CaseIterable {
        case resetBookInfo
        case resetReadingRecords
        case deleteBook

        var title: String {
            switch self {
            case .resetBookInfo:
                return String(localized: .`reset_delete.reset_book_info`)
            case .resetReadingRecords:
                return String(localized: .`reset_delete.reset_reading_records`)
            case .deleteBook:
                return String(localized: .`reset_delete.delete_book`)
            }
        }

        var textColor: UIColor {
            switch self {
            case .deleteBook:
                return .systemRed
            default:
                return .label
            }
        }
    }

    // MARK: - Setup

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = .systemBackground
        title = String(localized: .`reset_delete.title`)

        view.addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.delegate = self
    }

    // MARK: - Binding

    override func bind(reactor: ResetAndDeleteReactor) {

        // State
        reactor.state
            .map { $0.isResetSuccess }
            .distinctUntilChanged()
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isDeleteSuccess }
            .distinctUntilChanged()
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] _ in
                // 도서 삭제 성공 시 도서 상세 화면까지 닫기
                if let navigationController = self?.navigationController {
                    // BookDetailViewController까지 pop
                    let viewControllers = navigationController.viewControllers
                    if let bookDetailIndex = viewControllers.firstIndex(where: { $0 is BookDetailViewController }),
                       bookDetailIndex > 0 {
                        let targetViewController = viewControllers[bookDetailIndex - 1]
                        navigationController.popToViewController(targetViewController, animated: true)
                    } else {
                        navigationController.popToRootViewController(animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Helper Methods

    private func showResetBookInfoConfirmation() {
        let alert = UIAlertController(
            title: String(localized: .`reset_delete.reset_book_info_confirm_title`),
            message: String(localized: .`reset_delete.reset_book_info_confirm_message`),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .`action.reset`), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.resetBookInfo)
        })

        present(alert, animated: true)
    }

    private func showResetRecordsConfirmation() {
        let alert = UIAlertController(
            title: String(localized: .`reset_delete.reset_records_confirm_title`),
            message: String(localized: .`reset_delete.reset_records_confirm_message`),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .`action.reset`), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.resetReadingRecords)
        })

        present(alert, animated: true)
    }

    private func showDeleteBookConfirmation() {
        let alert = UIAlertController(
            title: String(localized: .`reset_delete.delete_book_confirm_title`),
            message: String(localized: .`reset_delete.delete_book_confirm_message`),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .`action.delete`), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteBook)
        })

        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension ResetAndDeleteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ResetOption.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let option = ResetOption.allCases[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = option.title
        config.textProperties.color = option.textColor
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let option = ResetOption.allCases[indexPath.row]

        switch option {
        case .resetBookInfo:
            showResetBookInfoConfirmation()
        case .resetReadingRecords:
            showResetRecordsConfirmation()
        case .deleteBook:
            showDeleteBookConfirmation()
        }
    }
}
