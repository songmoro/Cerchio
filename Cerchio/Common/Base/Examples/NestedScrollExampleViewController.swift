//
//  ViewController.swift
//  NestedCollectionView
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

/// Example implementation of NestedScrollViewController
/// Demonstrates how to subclass and customize the nested scroll pattern
class NestedScrollExampleViewController: NestedScrollViewController {

    // MARK: - Properties
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    private var itemCounters: [Section: Int] = [
        .section1: 20,
        .section2: 15
    ]
    
    // MARK: - Section Model
    nonisolated enum Section: Int, CaseIterable {
        case section1 = 0
        case section2 = 1

        var title: String {
            switch self {
            case .section1: return "섹션 1"
            case .section2: return "섹션 2"
            }
        }
    }

    // MARK: - Item Model
    nonisolated enum Item: Hashable {
        case content(id: String, text: String)
        case loadMore(id: String, sectionIndex: Int)

        var id: String {
            switch self {
            case .content(let id, _): return id
            case .loadMore(let id, _): return id
            }
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "중첩 스크롤 예제"
    }

    // MARK: - Override: Custom Info View
    override func createInfoView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.3)

        let label = UILabel()
        label.text = "정보 뷰\n(위로 스크롤하면 사라짐)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 18, weight: .medium)

        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        return view
    }

    // MARK: - Override: Custom Sticky Tab View
    override func createStickyTabView() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGreen

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 1

        // 섹션 1 버튼
        let section1Button = createTabButton(title: "섹션 1", tag: 0)
        section1Button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        // 섹션 2 버튼
        let section2Button = createTabButton(title: "섹션 2", tag: 1)
        section2Button.addTarget(self, action: #selector(tabButtonTapped(_:)), for: .touchUpInside)

        stackView.addArrangedSubview(section1Button)
        stackView.addArrangedSubview(section2Button)

        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        return view
    }

    private func createTabButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGreen
        button.tag = tag
        return button
    }

    @objc private func tabButtonTapped(_ sender: UIButton) {
        let sectionIndex = sender.tag
        scrollToSection(sectionIndex)
    }

    // MARK: - Override: Custom Collection View Layout
    override func createCollectionViewLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(80)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(80)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)

            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(44)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]

            return section
        }
    }

    // MARK: - Override: Setup Custom Content
    override func setupCustomContent() {
        // Register cells
        collectionView.register(ContentCell.self, forCellWithReuseIdentifier: ContentCell.reuseIdentifier)
        collectionView.register(LoadMoreCell.self, forCellWithReuseIdentifier: LoadMoreCell.reuseIdentifier)
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )

        // Configure data source
        configureDataSource()

        // Apply initial snapshot
        applyInitialSnapshot()
    }

    // MARK: - Diffable DataSource
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            switch item {
            case .content(_, let text):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ContentCell.reuseIdentifier,
                    for: indexPath
                ) as? ContentCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: text)
                return cell

            case .loadMore(_, let sectionIndex):
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: LoadMoreCell.reuseIdentifier,
                    for: indexPath
                ) as? LoadMoreCell else {
                    return UICollectionViewCell()
                }
                cell.onTap = { [weak self] in
                    self?.handleLoadMore(for: sectionIndex)
                }
                return cell
            }
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let header = collectionView.dequeueReusableSupplementaryView(
                      ofKind: kind,
                      withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                      for: indexPath
                  ) as? SectionHeaderView else {
                return nil
            }

            let section = Section.allCases[indexPath.section]
            header.configure(with: section.title)
            return header
        }
    }

    // MARK: - Data Management
    private func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        for section in Section.allCases {
            snapshot.appendSections([section])
            let items = createItems(for: section)
            snapshot.appendItems(items, toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
            self?.collectionView.layoutIfNeeded()
        }
    }

    private func createItems(for section: Section) -> [Item] {
        let count = itemCounters[section] ?? 0
        var items: [Item] = []

        for i in 1...count {
            let id = "\(section.rawValue)-\(i)"
            items.append(.content(id: id, text: "\(section.title) 셀 \(i)"))
        }

        let loadMoreId = "\(section.rawValue)-loadmore"
        items.append(.loadMore(id: loadMoreId, sectionIndex: section.rawValue))

        return items
    }

    // MARK: - Load More Action
    private func handleLoadMore(for sectionIndex: Int) {
        guard let section = Section(rawValue: sectionIndex) else { return }

        let currentCount = itemCounters[section] ?? 0
        itemCounters[section] = currentCount + 2

        var snapshot = dataSource.snapshot()
        let existingItems = snapshot.itemIdentifiers(inSection: section)
        snapshot.deleteItems(existingItems)

        let newItems = createItems(for: section)
        snapshot.appendItems(newItems, toSection: section)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Section Header View
class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(8)
        }
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}

class ContentCell: UICollectionViewCell {
    static let reuseIdentifier = "ContentCell"

    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 8

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with text: String) {
        label.text = text

        // Apply random background color
        contentView.backgroundColor = randomColor()

        // Adjust text color based on background brightness
        label.textColor = isLightColor(contentView.backgroundColor ?? .white) ? .black : .white
    }

    private func randomColor() -> UIColor {
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemPink, .systemTeal, .systemIndigo,
            .systemYellow, .systemMint, .systemCyan, .systemBrown
        ]
        return colors.randomElement()?.withAlphaComponent(0.7) ?? .systemGray
    }

    private func isLightColor(_ color: UIColor) -> Bool {
        var white: CGFloat = 0
        color.getWhite(&white, alpha: nil)
        return white > 0.5
    }
}


class LoadMoreCell: UICollectionViewCell {
    static let reuseIdentifier = "LoadMoreCell"

    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("더보기", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])

        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    @objc private func buttonTapped() {
        onTap?()
    }
}
