//
//  LibraryViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit
import SnapKit

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
        configureDesign()
        configureDataSource()
        loadData()
    }
    
    private func configureDesign() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "서재"
        
        let layout = MasonryLayout()
        collectionView.collectionViewLayout = layout
        layout.delegate = self
        
        collectionView.register(LibraryCollectionViewCell.self)
        
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(LibraryCollectionViewCell.self, for: indexPath)
            cell.configure(with: item)
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
}

extension LibraryViewController: MasonryLayoutProtocol {
    func collectionView(_ collectionView: UICollectionView, heightAtIndexPath indexPath:IndexPath) -> CGFloat {
        let book = books[indexPath.item]
        
        // TODO: 레이블 글자 크기 계산 개선
        return (UIScreen.main.bounds.height / 3) + CGFloat(max(1, book.title.count / 18) * 14) + CGFloat(max(1, book.author.count / 20) * 12)
    }
}
