//
//  QuoteListViewController.swift
//  Cerchio
//
//  Created by Claude on 9/30/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class QuoteListViewController: BaseViewController<QuoteListReactor> {
    private typealias DataSource = UITableViewDiffableDataSource<Section, Quote>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Quote>

    // MARK: - UI Components
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var dataSource: DataSource!

    // MARK: - Properties
    var onAddQuoteTapped: (() -> Void)?
    var onQuoteEditTapped: ((Quote) -> Void)?
    private var isEditMode: Bool = false

    // MARK: - Section Type
    nonisolated enum Section: CaseIterable {
        case quotes
    }

    // MARK: - Setup
    override func setupUI() {
        super.setupUI()
        setupNavigationBar()
        setupTableView()
        setupLayout()
        configureDataSource()
    }

    private func setupNavigationBar() {
        title = String(localized: .bookDetailSavedQuotes)

        // 추가 버튼
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )

        // 편집 버튼
        let editButton = UIBarButtonItem(
            title: NSLocalizedString("action.edit", comment: "Edit action"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )

        navigationItem.rightBarButtonItems = [addButton, editButton]
    }

    private func updateNavigationBar() {
        guard let rightBarButtonItems = navigationItem.rightBarButtonItems,
              rightBarButtonItems.count >= 2 else { return }

        let editButton = rightBarButtonItems[1]

        if isEditMode {
            editButton.title = NSLocalizedString("action.done", comment: "Done action")
            editButton.style = .done
        } else {
            editButton.title = NSLocalizedString("action.edit", comment: "Edit action")
            editButton.style = .plain
        }
    }

    private func setupTableView() {
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .singleLine
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "QuoteCell")

        view.addSubview(tableView)
    }

    private func setupLayout() {
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { tableView, indexPath, quote in
            let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCell", for: indexPath)

            var config = cell.defaultContentConfiguration()
            config.text = "\"\(quote.quote)\""
            config.textProperties.numberOfLines = 0

            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none

            var secondaryTextParts: [String] = []
            if let pageNumber = quote.pageNumber {
                secondaryTextParts.append("p.\(pageNumber)")
            }
            secondaryTextParts.append(formatter.string(from: quote.createdAt))

            config.secondaryText = secondaryTextParts.joined(separator: " · ")
            config.secondaryTextProperties.color = .secondaryLabel

            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator

            return cell
        }

        // 스와이프 삭제
        tableView.delegate = self
    }

    override func bind(reactor: QuoteListReactor) {
        // Action
        Observable.just(QuoteListReactor.Action.loadQuotes)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.quotes }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] quotes in
                self?.updateSnapshot(with: quotes)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { isLoading in
                print("Loading: \(isLoading)")
            })
            .disposed(by: disposeBag)
    }

    private func updateSnapshot(with quotes: [Quote]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.quotes])
        snapshot.appendItems(quotes, toSection: .quotes)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        onAddQuoteTapped?()
    }

    @objc private func editButtonTapped() {
        isEditMode.toggle()
        tableView.setEditing(isEditMode, animated: true)
        updateNavigationBar()
    }
}

// MARK: - UITableViewDelegate
extension QuoteListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let quote = dataSource.itemIdentifier(for: indexPath) else { return }
        onQuoteEditTapped?(quote)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let quote = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("action.delete", comment: "Delete action")) { [weak self] _, _, completion in
            self?.deleteQuote(quote)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let quote = dataSource.itemIdentifier(for: indexPath) else { return }
            deleteQuote(quote)
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return false // 순서 변경은 비활성화
    }

    private func deleteQuote(_ quote: Quote) {
        reactor?.action.onNext(.deleteQuote(quote.id))
    }
}
