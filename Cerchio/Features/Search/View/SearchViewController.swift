//
//  SearchViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class SearchViewController: BaseViewController<SearchReactor> {
    private typealias DataSource = UITableViewDiffableDataSource<Section, Book>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Book>

    // MARK: - UI Components
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "ISBN, 도서명, 작가 등 검색 키워드"
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .custom(weight: .medium, size: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties
    private var dataSource: DataSource!

    nonisolated enum Section: CaseIterable, Hashable, Sendable {
        case results
    }

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        navigationItem.title = "도서 검색"
        
        setupSearchBar()
        setupTableView()
        setupEmptyState()
        setupLayout()
        configureDataSource()
    }

    override func bind(reactor: SearchReactor) {
        // Action
        searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .map { SearchReactor.Action.searchTextChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .map { SearchReactor.Action.searchButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.searchState }
            .distinctUntilChanged { $0.description == $1.description }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] searchState in
                self?.updateUI(for: searchState)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)

    }

    // MARK: - Setup Methods
    private func setupSearchBar() {
        view.addSubview(searchBar)
        searchBar.showsCancelButton = true
        searchBar.delegate = self

        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        tableView.rowHeight = SearchResultConstants.Layout.rowHeight
        tableView.contentInset.bottom = 20
        tableView.scrollIndicatorInsets.bottom = 20
    }

    private func setupEmptyState() {
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(SearchResultConstants.Layout.emptyStateInset)
        }
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)

        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyStateView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    // MARK: - DataSource Configuration
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, book: Book) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath) as! SearchResultTableViewCell
            cell.configure(with: book) { [weak self] selectedBook in
                self?.reactor?.action.onNext(.addBookToLibrary(selectedBook))
            }
            return cell
        }

        tableView.dataSource = dataSource
    }

    // MARK: - UI Updates
    private func updateUI(for searchState: SearchState) {
        switch searchState {
        case .initial:
            showEmptyState(message: "검색어를 입력해주세요.")
            updateSnapshot(with: [])

        case .searching:
            hideEmptyState()

        case .results(let books):
            hideEmptyState()
            updateSnapshot(with: books)

        case .noResults:
            showEmptyState(message: "검색 결과가 없습니다.")
            updateSnapshot(with: [])

        case .error(let message):
            showEmptyState(message: "오류가 발생했습니다.\n\(message)")
            updateSnapshot(with: [])
        }
    }

    private func showEmptyState(message: String) {
        emptyStateLabel.text = message
        emptyStateView.isHidden = false
        tableView.isHidden = true
    }

    private func hideEmptyState() {
        emptyStateView.isHidden = true
        tableView.isHidden = false
    }

    private func updateSnapshot(with books: [Book]) {
        var snapshot = Snapshot()
        if !books.isEmpty {
            snapshot.appendSections([Section.results])
            snapshot.appendItems(books, toSection: Section.results)
        }
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}


// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
