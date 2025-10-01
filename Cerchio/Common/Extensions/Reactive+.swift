//
//  Reactive+.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UITableView {
    func sectionSelected<S, I>(_ dataSource: UITableViewDiffableDataSource<S, I>) -> ControlEvent<S> where S: Hashable, I: Hashable {
        let source: Observable<S> = self.itemSelected
            .compactMap { [weak dataSource] indexPath in
                dataSource?.sectionIdentifier(for: indexPath.section)
            }

        return ControlEvent(events: source)
    }

    func itemSelected<S, I>(_ dataSource: UITableViewDiffableDataSource<S, I>) -> ControlEvent<I> where S: Hashable, I: Hashable {
        let source: Observable<I> = self.itemSelected
            .compactMap { [weak dataSource] indexPath in
                dataSource?.itemIdentifier(for: indexPath)
            }

        return ControlEvent(events: source)
    }

    func itemDeselected<S, I>(_ dataSource: UITableViewDiffableDataSource<S, I>) -> ControlEvent<I> where S: Hashable, I: Hashable {
        let source: Observable<I> = self.itemDeselected
            .compactMap { [weak dataSource] indexPath in
                dataSource?.itemIdentifier(for: indexPath)
            }

        return ControlEvent(events: source)
    }

    func modelAtIndexPath<S, I>(_ dataSource: UITableViewDiffableDataSource<S, I>) -> (Observable<IndexPath>) -> Observable<I> where S: Hashable, I: Hashable {
        return { indexPath in
            indexPath.compactMap { [weak dataSource] indexPath in
                dataSource?.itemIdentifier(for: indexPath)
            }
        }
    }

    func willDisplayCell<S, I>(_ dataSource: UITableViewDiffableDataSource<S, I>) -> Observable<(cell: UITableViewCell, item: I, indexPath: IndexPath)> where S: Hashable, I: Hashable {
        return self.willDisplayCell
            .compactMap { [weak dataSource] (cell, indexPath) in
                guard let item = dataSource?.itemIdentifier(for: indexPath) else { return nil }
                return (cell, item, indexPath)
            }
    }
}

extension Reactive where Base: UICollectionView {
    func sectionSelected<S, I>(_ dataSource: UICollectionViewDiffableDataSource<S, I>) -> ControlEvent<S> where S: Hashable, I: Hashable {
        let source: Observable<S> = self.itemSelected
            .compactMap { [weak dataSource] indexPath in
                dataSource?.sectionIdentifier(for: indexPath.section)
            }

        return ControlEvent(events: source)
    }

    func itemSelected<S, I>(_ dataSource: UICollectionViewDiffableDataSource<S, I>) -> ControlEvent<I> where S: Hashable, I: Hashable {
        let source: Observable<I> = self.itemSelected
            .compactMap { [weak dataSource] indexPath in
                dataSource?.itemIdentifier(for: indexPath)
            }

        return ControlEvent(events: source)
    }

    func itemDeselected<S, I>(_ dataSource: UICollectionViewDiffableDataSource<S, I>) -> ControlEvent<I> where S: Hashable, I: Hashable {
        let source: Observable<I> = self.itemDeselected
            .compactMap { [weak dataSource] indexPath in
                dataSource?.itemIdentifier(for: indexPath)
            }

        return ControlEvent(events: source)
    }

    func modelAtIndexPath<S, I>(_ dataSource: UICollectionViewDiffableDataSource<S, I>) -> (Observable<IndexPath>) -> Observable<I> where S: Hashable, I: Hashable {
        return { indexPath in
            indexPath.compactMap { [weak dataSource] indexPath in
                dataSource?.itemIdentifier(for: indexPath)
            }
        }
    }

    func willDisplayCell<S, I>(_ dataSource: UICollectionViewDiffableDataSource<S, I>) -> Observable<(cell: UICollectionViewCell, item: I, indexPath: IndexPath)> where S: Hashable, I: Hashable {
        return self.willDisplayCell
            .compactMap { [weak dataSource] (cell, indexPath) in
                guard let item = dataSource?.itemIdentifier(for: indexPath) else { return nil }
                return (cell, item, indexPath)
            }
    }
}
