//
//  LibraryViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit
import SnapKit
import Kingfisher

final class BookCollectionViewCell: UICollectionViewCell, IsIdentifiable {
    private let coverImageView = UIImageView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.layer.cornerRadius = 8
        coverImageView.backgroundColor = .systemGray5
        contentView.addSubview(coverImageView)
        
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        
        authorLabel.font = .systemFont(ofSize: 12, weight: .regular)
        authorLabel.textColor = .secondaryLabel
        authorLabel.numberOfLines = 0
        contentView.addSubview(authorLabel)
    }
    
    private func setupConstraints() {
        coverImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(8)
            $0.height.equalTo(coverImageView.snp.width).multipliedBy(4.0/3.0) // 3:4 비율
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(8)
        }
        
        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(4)
        }
    }
    
    private func getLabelHeight() -> CGFloat {
        fatalError("미사용")
//        return titleLabel.bounds.height + authorLabel.bounds.height
    }
    
    func configure(with item: Book) {
        titleLabel.text = item.title
        authorLabel.text = item.author
        
        guard let url = URL(string: item.image) else { return }
        coverImageView.kf.setImage(with: url)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
    }
}

final class LibraryViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Book>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Book>
    
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!
    
    nonisolated enum Section: CaseIterable {
        case book
    }
    
    private let books = Book.sample
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupDataSource()
        loadData()
    }
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "서재"
        
        let layout = MasonryLayout()
        collectionView.collectionViewLayout = layout
        layout.delegate = self
        
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(BookCollectionViewCell.self)
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func setupDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell: BookCollectionViewCell = collectionView.dequeueReusableCell(BookCollectionViewCell.self, for: indexPath)
            cell.configure(with: item)
            
//            print(indexPath, item)
//            cell.layer.borderColor = indexPath.section % 2 == 0 ? UIColor.red.cgColor : UIColor.blue.cgColor
//            cell.layer.borderWidth = 1
            return cell
        }
        
        collectionView.dataSource = dataSource
    }
    
    private func loadData() {
        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        snapshot.appendItems(books, toSection: .book)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
//    private func loadData() {
//        var leftBooks: [Book] = []
//        var rightBooks: [Book] = []
//        
//        for (index, book) in book.enumerated() {
//            if index % 2 == 0 {
//                leftBooks.append(book)
//            }
//            else {
//                rightBooks.append(book)
//            }
//        }
//        
//        var snapshot = Snapshot()
//        snapshot.appendSections([.left, .right])
//        snapshot.appendItems(leftBooks, toSection: .left)
//        snapshot.appendItems(rightBooks, toSection: .right)
//        dataSource.apply(snapshot, animatingDifferences: false)
//    }
    
//    private func makeLayout() -> UICollectionViewCompositionalLayout {
//        let configuration = UICollectionViewCompositionalLayoutConfiguration()
//        configuration.scrollDirection = .vertical
//        
//        let layout = UICollectionViewCompositionalLayout { section, layoutEnvironment in
//            let itemSize = NSCollectionLayoutSize(
//                widthDimension: .fractionalWidth(0.5),
//                heightDimension: .estimated(200)
//            )
//            let item = NSCollectionLayoutItem(layoutSize: itemSize)
//            
//            let groupSize = NSCollectionLayoutSize(
//                widthDimension: .fractionalWidth(1.0),
//                heightDimension: .estimated(2000)
//            )
//            let group = NSCollectionLayoutGroup.horizontal(
//                layoutSize: groupSize,
//                subitems: [item],
//            )
//            let containerGroupSize = NSCollectionLayoutSize(
//                widthDimension: .fractionalWidth(1.0),
//                heightDimension: .estimated(2000)
//            )
//            let containerGroup = NSCollectionLayoutGroup.vertical(
//                layoutSize: containerGroupSize,
//                subitems: [group]
//            )
//            
//            let section = NSCollectionLayoutSection(group: group)
//            
//            return section
//        }
//        layout.configuration = configuration
//        
//        return layout
//    }
}

extension LibraryViewController: MasonryLayoutProtocol {
    func collectionView(_ collectionView: UICollectionView, heightAtIndexPath indexPath:IndexPath) -> CGFloat {
        let book = books[indexPath.item]
        return (UIScreen.main.bounds.height / 3) + CGFloat(max(1, book.title.count / 18) * 14) + CGFloat(max(1, book.author.count / 20) * 12)
    }
}
