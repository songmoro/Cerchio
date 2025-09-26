//
//  LibraryViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/23/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class LibraryViewController: BaseViewController<LibraryReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Book>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Book>

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!

    nonisolated enum Section: CaseIterable {
        case book
    }

    override func setupUI() {
        super.setupUI()

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

        configureDataSource()
    }

    override func bind(reactor: LibraryReactor) {
        // Action
        Observable.just(LibraryReactor.Action.loadBooks)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // Collection View Selection
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self,
                      let reactor = self.reactor else { return }

                let books = reactor.currentState.books
                guard indexPath.item < books.count else { return }

                let selectedBook = books[indexPath.item]
                if let libraryCoordinator = self.coordinator as? LibraryCoordinator {
                    libraryCoordinator.showBookDetail(selectedBook)
                }
            })
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.books }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] books in
                self?.updateData(books: books)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                self?.handleLoadingState(isLoading)
            })
            .disposed(by: disposeBag)
    }

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(LibraryCollectionViewCell.self, for: indexPath)
            cell.configure(with: item)
            return cell
        }

        collectionView.dataSource = dataSource

        // 기본 섹션 설정
        setupInitialSnapshot()
    }

    private func setupInitialSnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 뷰의 레이아웃이 완료된 후 컬렉션 뷰 레이아웃 업데이트
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func updateData(books: [Book]) {
        guard let dataSource = dataSource else { return }

        var snapshot = Snapshot()
        snapshot.appendSections([.book])
        snapshot.appendItems(books, toSection: .book)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func handleLoadingState(_ isLoading: Bool) {
        if isLoading {
            // TODO: 로딩 인디케이터 표시
            print("Loading books...")
        } else {
            // TODO: 로딩 인디케이터 숨기기
            print("Loading completed")
        }
    }
}

extension LibraryViewController: MasonryLayoutProtocol {
    func collectionView(_ collectionView: UICollectionView, heightAtIndexPath indexPath: IndexPath) -> CGFloat {
        guard let reactor = reactor else { return 200 }

        let books = reactor.currentState.books
        guard indexPath.item < books.count else { return 200 }

        let book = books[indexPath.item]

        // TODO: 레이블 글자 크기 계산 개선
        return (UIScreen.main.bounds.height / 3) + CGFloat(max(1, book.title.count / 18) * 14) + CGFloat(max(1, book.author.count / 20) * 12)
    }
}
