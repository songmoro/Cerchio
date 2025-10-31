//
//  SearchHistoryEditViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/31/25.
//

@preconcurrency import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RealmSwift

nonisolated(unsafe) private enum Section: Hashable, Sendable {
    case main
}

final class SearchHistoryEditViewController: UIViewController {
    var onHistoryUpdated: (() -> Void)?

    private let searchHistoryRepository: SearchHistoryRepositoryProtocol
    private let disposeBag = DisposeBag()
    private var dataSource: (any UICollectionViewDataSource)!
    private var diffableDataSource: UICollectionViewDiffableDataSource<Section, SearchHistoryDTO>!
    private var historyItems: [SearchHistoryDTO] = []

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .systemBackground
        return collectionView
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .`search.history.empty`)
        label.textAlignment = .center
        label.font = .custom(weight: .medium, size: 16)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()

    init(searchHistoryRepository: SearchHistoryRepositoryProtocol) {
        self.searchHistoryRepository = searchHistoryRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        configureDataSource()
        loadHistory()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)
        view.addSubview(emptyStateLabel)

        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        emptyStateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.horizontalEdges.equalToSuperview().inset(40)
        }
    }

    private func setupNavigationBar() {
        title = String(localized: .`search.history.edit_title`)

        let deleteAllButton = UIBarButtonItem(
            title: String(localized: .`search.history.delete_all`),
            style: .plain,
            target: self,
            action: #selector(deleteAllTapped)
        )
        deleteAllButton.tintColor = .systemRed

        let doneButton = UIBarButtonItem(
            title: String(localized: .`action.done`),
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        doneButton.tintColor = .forestGreen

        navigationItem.leftBarButtonItem = deleteAllButton
        navigationItem.rightBarButtonItem = doneButton
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection in
            // Item with estimated size
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .estimated(100),
                heightDimension: .estimated(44)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group with full width and estimated height
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: [item]
            )
            group.interItemSpacing = .fixed(8)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

            return section
        }
        return layout
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<SearchHistoryCell, SearchHistoryDTO> { [weak self] cell, indexPath, item in
            let truncatedKeyword = String(item.keyword.prefix(10))
            let displayKeyword = truncatedKeyword.count < item.keyword.count ? truncatedKeyword + "..." : truncatedKeyword

            // Add X mark to the end of keyword
            let displayText = displayKeyword + " ✕"
            cell.configure(with: displayText)
            cell.onTapped = { [weak self] in
                HapticFeedbackManager.shared.impact()
                self?.deleteHistory(item)
            }
        }

        diffableDataSource = UICollectionViewDiffableDataSource<Section, SearchHistoryDTO>(collectionView: collectionView) { (collectionView: UICollectionView, indexPath: IndexPath, item: SearchHistoryDTO) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
        dataSource = diffableDataSource
    }

    private func loadHistory() {
        searchHistoryRepository.getAllSearchHistory()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] history in
                guard let self = self else { return }
                let uniqueHistory = self.deduplicateSearchHistory(history)
                // Convert Realm objects to DTOs
                let dtoItems = uniqueHistory.map { SearchHistoryDTO(from: $0) }
                self.historyItems = dtoItems
                self.updateSnapshot(with: dtoItems)
            })
            .disposed(by: disposeBag)
    }

    private func deduplicateSearchHistory(_ history: [RealmSearchHistory]) -> [RealmSearchHistory] {
        var seenKeywords: Set<String> = []
        var uniqueHistory: [RealmSearchHistory] = []

        for item in history {
            let lowercasedKeyword = item.keyword.lowercased()
            if !seenKeywords.contains(lowercasedKeyword) {
                seenKeywords.insert(lowercasedKeyword)
                uniqueHistory.append(item)
            }
        }

        return uniqueHistory
    }

    private func updateSnapshot(with items: [SearchHistoryDTO]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SearchHistoryDTO>()

        if items.isEmpty {
            emptyStateLabel.isHidden = false
            collectionView.isHidden = true
            navigationItem.leftBarButtonItem?.isEnabled = false
        } else {
            emptyStateLabel.isHidden = true
            collectionView.isHidden = false
            navigationItem.leftBarButtonItem?.isEnabled = true

            snapshot.appendSections([Section.main])
            snapshot.appendItems(items, toSection: Section.main)
        }

        diffableDataSource.apply(snapshot, animatingDifferences: true)
    }

    private func deleteHistory(_ item: SearchHistoryDTO) {
        guard let objectId = try? ObjectId(string: item.id) else { return }
        searchHistoryRepository.deleteSearchHistory(id: objectId)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.loadHistory()
                self?.onHistoryUpdated?()
            })
            .disposed(by: disposeBag)
    }

    @objc private func deleteAllTapped() {
        let alert = UIAlertController(
            title: String(localized: .`search.history.delete_all_confirmation.title`),
            message: String(localized: .`search.history.delete_all_confirmation.message`),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel)
        let deleteAction = UIAlertAction(title: String(localized: .`action.delete`), style: .destructive) { [weak self] _ in
            self?.deleteAllHistory()
        }

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)

        present(alert, animated: true)
    }

    private func deleteAllHistory() {
        searchHistoryRepository.deleteAllSearchHistory()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.historyItems = []
                self?.updateSnapshot(with: [])
                self?.onHistoryUpdated?()
            })
            .disposed(by: disposeBag)
    }

    @objc private func doneTapped() {
        HapticFeedbackManager.shared.impact()
        dismiss(animated: true)
    }
}

// MARK: - SearchHistoryCell

final class SearchHistoryCell: UICollectionViewCell {
    var onTapped: (() -> Void)?

    private let button: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseForegroundColor = .forestGreen
        config.baseBackgroundColor = .clear
        config.background.strokeColor = .forestGreen
        config.background.strokeWidth = 1
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        config.cornerStyle = .capsule

        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .custom(weight: .regular, size: 14)
            return outgoing
        }

        let button = UIButton(configuration: config)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(button)

        button.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        // Set content hugging and compression resistance
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentHuggingPriority(.required, for: .vertical)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    func configure(with text: String) {
        button.configuration?.title = text
    }

    @objc private func buttonTapped() {
        onTapped?()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: UIView.layoutFittingCompressedSize.height)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )
        return layoutAttributes
    }
}
