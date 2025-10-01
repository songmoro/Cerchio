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
}
