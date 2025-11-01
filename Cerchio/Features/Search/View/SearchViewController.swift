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

    var onBookSaved: ((Book) -> Void)?
    private var searchHistoryRepository: SearchHistoryRepositoryProtocol?

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = String(localized: .`search.placeholder`)
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()

    private let searchHistoryScrollView = SearchHistoryScrollView()

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

    private var dataSource: DataSource!

    nonisolated enum Section: CaseIterable, Hashable, Sendable {
        case results
    }

    override func setupUI() {
        super.setupUI()

        setupSearchBar()
        setupTableView()
        setupEmptyState()
        setupLayout()
        configureDataSource()
        setupTapGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reactor?.action.onNext(.refresh)
        reactor?.action.onNext(.loadSearchHistory)
    }

    override func bind(reactor: SearchReactor) {
        searchBar.rx.text.orEmpty
            .distinctUntilChanged()
            .map { SearchReactor.Action.searchTextChanged($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        searchBar.rx.searchButtonClicked
            .map { SearchReactor.Action.searchButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

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

        reactor.state
            .map { $0.error }
            .distinctUntilChanged()
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] errorMessage in
                self?.showErrorAlert(message: errorMessage)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.lastSavedBook }
            .distinctUntilChanged { $0?.isbn == $1?.isbn }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] savedBook in
                self?.showNavigationConfirmAlert(for: savedBook)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.searchHistory }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] keywords in
                self?.searchHistoryScrollView.updateHistory(keywords)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.searchText }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(searchBar.rx.text)
            .disposed(by: disposeBag)

        searchHistoryScrollView.onHistorySelected = { [weak self] keyword in
            self?.reactor?.action.onNext(.selectSearchHistory(keyword))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.reactor?.action.onNext(.searchButtonTapped)
            }
        }

        searchHistoryScrollView.onEditTapped = { [weak self] in
            self?.showHistoryEditScreen()
        }
    }

    func configure(searchHistoryRepository: SearchHistoryRepositoryProtocol) {
        self.searchHistoryRepository = searchHistoryRepository
    }

    private func showHistoryEditScreen() {
        guard let repository = searchHistoryRepository else { return }

        let editViewController = SearchHistoryEditViewController(searchHistoryRepository: repository)
        editViewController.onHistoryUpdated = { [weak self] in
            self?.reactor?.action.onNext(.loadSearchHistory)
        }

        let navigationController = UINavigationController(rootViewController: editViewController)
        present(navigationController, animated: true)
    }

    private func setupSearchBar() {
        view.addSubview(searchBar)
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        searchBar.tintColor = .forestGreen

        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.horizontalEdges.equalToSuperview()
        }
    }

    private func setupTableView() {
        tableView.register(SearchResultTableViewCell.self, forCellReuseIdentifier: SearchResultTableViewCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.contentInset.bottom = 20
        tableView.verticalScrollIndicatorInsets = .init(top: 0, left: 0, bottom: 20, right: 0)
        tableView.delegate = self
    }

    private func setupEmptyState() {
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(SearchResultConstants.Layout.emptyStateInset)
        }
    }

    private func setupLayout() {
        view.addSubview(searchHistoryScrollView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)

        searchHistoryScrollView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom)
            $0.horizontalEdges.equalToSuperview()
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(searchHistoryScrollView.snp.bottom)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyStateView.snp.makeConstraints {
            $0.top.equalTo(searchHistoryScrollView.snp.bottom)
            $0.horizontalEdges.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTap() {
        searchBar.resignFirstResponder()
    }

    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, book: Book) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.identifier, for: indexPath) as! SearchResultTableViewCell
            cell.configure(
                with: book,
                addHandler: { [weak self] selectedBook in
                    guard let self = self else { return }
                    self.reactor?.action.onNext(.addBookToLibrary(selectedBook))
                },
                onExpandToggled: { [weak tableView] in
                    UIView.animate(withDuration: SearchResultConstants.Animation.expandAnimationDuration) {
                        tableView?.beginUpdates()
                        tableView?.endUpdates()
                    }
                }
            )
            return cell
        }

        tableView.dataSource = dataSource
    }

    private func showNavigationConfirmAlert(for book: Book) {
        let alert = UIAlertController(
            title: String(localized: .`search.book_saved.title`),
            message: String(localized: .`search.book_saved.message`),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel)

        let goToDetailAction = UIAlertAction(title: String(localized: .`search.navigate`), style: .default) { [weak self] _ in
            self?.onBookSaved?(book)
        }

        alert.addAction(cancelAction)
        alert.addAction(goToDetailAction)

        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: String(localized: .`alert.notification`),
            message: message,
            preferredStyle: .alert
        )

        let okAction = UIAlertAction(title: String(localized: .`action.confirm`), style: .default)
        alert.addAction(okAction)

        present(alert, animated: true)
    }

    private func updateUI(for searchState: SearchState) {
        switch searchState {
        case .initial:
            showEmptyState(message: String(localized: .`search.empty_state.enter_query`))
            updateSnapshot(with: [])

        case .searching:
            hideEmptyState()

        case .results(let books, _):
            hideEmptyState()
            updateSnapshot(with: books)

        case .noResults:
            showEmptyState(message: String(localized: .`search.empty_state.no_results`))
            updateSnapshot(with: [])

        case .error(let message):
            let format = NSLocalizedString("alert.error.generic_message_format", comment: "")
            showEmptyState(message: String(format: format, message))
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

extension SearchViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        if offsetY > contentHeight - frameHeight - 100 {
            reactor?.action.onNext(.loadMore)
        }
    }
}
