//
//  BookDetailViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/28/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit
import RealmSwift

final class BookDetailViewController: BaseViewController<BookDetailReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    // MARK: - UI Components
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: .init())
    private var dataSource: DataSource!

    // MARK: - Child Coordinators
    private var childCoordinators: [Coordinator] = []
    
    // MARK: - Section & Item Types
    nonisolated enum Section: CaseIterable {
        case bookInfo
        case savedQuotes
        case photoPages
    }
    
    nonisolated enum Item: Hashable {
        case bookInfo(BookDetail)
        case savedQuote(String, Date) // 문장 텍스트, 저장 날짜 (임시 모델)
        case photoPage(UIImage?) // 임시 이미지 데이터
    }
    
    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        setupNavigationBar()
        setupCollectionView()
        setupLayout()
        configureDataSource()
    }
    
    private func setupNavigationBar() {
        // 즐겨찾기 버튼
        let favoriteButton = UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(favoriteButtonTapped)
        )
        
        // 삭제 버튼
        let deleteButton = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(deleteButtonTapped)
        )
        
        navigationItem.rightBarButtonItems = [deleteButton, favoriteButton]
    }
    
    @objc private func favoriteButtonTapped() {
        reactor?.action.onNext(.toggleFavorite)
    }
    
    @objc private func deleteButtonTapped() {
        reactor?.action.onNext(.deleteBook)
    }
    
    private func updateFavoriteButton(isFavorite: Bool) {
        guard let rightBarButtonItems = navigationItem.rightBarButtonItems,
              rightBarButtonItems.count >= 2 else { return }
        
        let favoriteButton = rightBarButtonItems[1] // 두 번째 버튼이 즐겨찾기 버튼
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.image = UIImage(systemName: imageName)
    }
    
    override func bind(reactor: BookDetailReactor) {
        // Action
        Observable.just(BookDetailReactor.Action.loadBookDetail)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        // State
        reactor.state
            .map { $0.bookDetail }
            .compactMap { $0 }
            .distinctUntilChanged { lhs, rhs in
                lhs.book.isbn == rhs.book.isbn
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] bookDetail in
                self?.updateSnapshot(with: bookDetail)
                self?.loadPhotosAndUpdateUI() // 사진 데이터도 함께 로드
                self?.loadQuotesAndUpdateUI() // 문장 데이터도 함께 로드
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                // TODO: 로딩 인디케이터 처리
                print("Loading: \(isLoading)")
            })
            .disposed(by: disposeBag)
        
        reactor.state
            .map { $0.error }
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] error in
                // TODO: 에러 처리
                print("Error: \(error)")
            })
            .disposed(by: disposeBag)
        
        // 즐겨찾기 상태 바인딩
        reactor.state
            .map { $0.isFavorite }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isFavorite in
                self?.updateFavoriteButton(isFavorite: isFavorite)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Setup Methods
    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        
        // 셀 등록
        collectionView.register(BookInfoCollectionViewCell.self)
        collectionView.register(SavedQuoteCell.self)
        collectionView.register(PhotoPageCell.self)
        
        view.addSubview(collectionView)
    }
    
    private func setupLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 컴포지셔널 레이아웃 설정
        collectionView.collectionViewLayout = createCompositionalLayout()
    }
    
    private func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self else { return nil }
            
            let section = Section.allCases[sectionIndex]
            switch section {
            case .bookInfo:
                return self.createBookInfoSection()
            case .savedQuotes:
                return self.createSavedQuotesSection()
            case .photoPages:
                return self.createPhotoPagesSection()
            }
        }
    }
    
    private func createBookInfoSection() -> NSCollectionLayoutSection {
        // 도서 정보 섹션 - 전체 화면 너비 사용
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(BookDetailConstants.Layout.estimatedHeight) // 예상 높이, 자동 조정됨
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(BookDetailConstants.Layout.estimatedHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = BookDetailConstants.Layout.sectionContentInsets
        
        return section
    }
    
    private func createSavedQuotesSection() -> NSCollectionLayoutSection {
        // 저장한 문장 섹션 - 화면 높이의 1/3
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0/3.0) // 화면 높이의 1/3
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        return section
    }
    
    private func createPhotoPagesSection() -> NSCollectionLayoutSection {
        // 찍은 사진 섹션 - 화면 높이의 1/3
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0/3.0) // 화면 높이의 1/3
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        return section
    }
    
    // MARK: - DataSource Configuration
    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, item in
            switch item {
            case .bookInfo(let bookDetail):
                let cell: BookInfoCollectionViewCell = collectionView.dequeueReusableCell(BookInfoCollectionViewCell.self, for: indexPath)
                cell.configure(with: bookDetail)
                return cell
                
            case .savedQuote(let quote, let date):
                let cell: SavedQuoteCell = collectionView.dequeueReusableCell(SavedQuoteCell.self, for: indexPath)
                cell.configure(with: quote, date: date)
                cell.onAddQuoteTapped = { [weak self] in
                    self?.showQuoteEntry()
                }
                return cell
                
            case .photoPage(let images):
                let cell: PhotoPageCell = collectionView.dequeueReusableCell(PhotoPageCell.self, for: indexPath)
                let imageArray: [UIImage?] = images != nil ? [images] : []
                cell.configure(with: imageArray)
                cell.onAddPhotoTapped = { [weak self] in
                    self?.showPhotoCapture()
                }
                cell.onPhotoLongPressed = { [weak self] imageView, image in
                    self?.showPhotoContextMenu(for: imageView, with: image)
                }
                return cell
            }
        }
    }
    
    private func updateSnapshot(with bookDetail: BookDetail) {
        var snapshot = Snapshot()
        snapshot.appendSections([.bookInfo, .savedQuotes, .photoPages])

        // 책 정보
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        // 저장한 문장 (기본 빈 데이터, 실제 데이터는 별도 로드)
        snapshot.appendItems([.savedQuote("", Date())], toSection: .savedQuotes)

        // 찍은 사진 (기본 빈 데이터, 실제 데이터는 별도 로드)
        snapshot.appendItems([.photoPage(nil)], toSection: .photoPages)

        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Navigation Methods
    private func showQuoteEntry() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        let quoteSaveCoordinator = QuoteSaveCoordinator(
            navigationController: navigationController ?? UINavigationController(),
            dependencies: QuoteSaveCoordinator.Dependencies(bookId: bookId)
        )

        addChildCoordinator(quoteSaveCoordinator)

        quoteSaveCoordinator.result
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .quoteSaved(let quote):
                    print("✅ Quote saved: \(quote)")
                    self?.loadQuotesAndUpdateUI()
                case .cancelled:
                    print("📝 Quote save cancelled")
                }
                self?.removeChildCoordinator(quoteSaveCoordinator)
            })
            .disposed(by: disposeBag)

        quoteSaveCoordinator.start()
    }
    
    private func showPhotoCapture() {
        print("사진 촬영 화면으로 이동")
        
        CameraPermissionManager.shared.handleCameraPermission(from: self) { [weak self] granted in
            guard granted else {
                print("❌ Camera permission denied")
                return
            }
            
            self?.presentCameraViewController()
        }
    }
    
    private func presentCameraViewController() {
        let cameraVC = CameraViewController()
        cameraVC.delegate = self
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    private func savePhoto(_ image: UIImage) {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)
        
        // 로컬 저장
        let imageName = ImageStorageManager.shared.generateUniqueImageName(for: bookId)
        guard let localPath = ImageStorageManager.shared.saveImage(image, withName: imageName) else {
            print("❌ Failed to save image locally")
            return
        }
        
        // Realm 저장
        let realmPhoto = RealmPhoto(
            bookId: bookId,
            localImagePath: localPath
        )
        
        if savePhotoToRealm(realmPhoto) {
            print("✅ Photo saved successfully")
            loadPhotosAndUpdateUI()
        } else {
            print("❌ Failed to save photo to Realm")
            ImageStorageManager.shared.deleteImage(atPath: localPath)
        }
    }
    
    private func savePhotoToRealm(_ realmPhoto: RealmPhoto) -> Bool {
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(realmPhoto)
            }
            return true
        } catch {
            return false
        }
    }
    
    private func loadPhotosAndUpdateUI() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)
        
        do {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            let photoArray = Array(photos)
            
            updateSnapshotWithPhotos(bookDetail: reactor.currentState.bookDetail, photos: photoArray)
        } catch {
            print("❌ Failed to load photos: \(error.localizedDescription)")
        }
    }
    
    private func loadQuotesAndUpdateUI() {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        do {
            let realm = try Realm()
            let quotes = realm.objects(RealmQuote.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)
            let quoteArray = Array(quotes)
            
            updateSnapshotWithAllData(
                bookDetail: reactor.currentState.bookDetail,
                quotes: quoteArray,
                photos: nil // 포토는 별도로 로드
            )
        } catch {
            print("❌ Failed to load quotes: \(error.localizedDescription)")
        }
    }

    private func updateSnapshotWithPhotos(bookDetail: BookDetail?, photos: [RealmPhoto]) {
        guard let bookDetail = bookDetail else { return }
        let bookId = String(describing: bookDetail.book.id)

        // 문장 데이터도 함께 로드해서 전체 업데이트
        do {
            let realm = try Realm()
            let quotes = realm.objects(RealmQuote.self)
                .filter("bookId == %@", bookId)
                .sorted(byKeyPath: "createdAt", ascending: false)
            let quoteArray = Array(quotes)
            
            updateSnapshotWithAllData(
                bookDetail: bookDetail,
                quotes: quoteArray,
                photos: photos
            )
        } catch {
            print("❌ Failed to load quotes during photo update: \(error.localizedDescription)")
            updateSnapshotWithAllData(
                bookDetail: bookDetail,
                quotes: [],
                photos: photos
            )
        }
    }

    private func updateSnapshotWithAllData(bookDetail: BookDetail?, quotes: [RealmQuote], photos: [RealmPhoto]?) {
        guard let bookDetail = bookDetail else { return }

        var snapshot = Snapshot()
        snapshot.appendSections([.bookInfo, .savedQuotes, .photoPages])

        // 책 정보
        snapshot.appendItems([.bookInfo(bookDetail)], toSection: .bookInfo)

        // 저장한 문장 - 실제 데이터로 업데이트
        if let latestQuote = quotes.first {
            snapshot.appendItems([.savedQuote(latestQuote.quote, latestQuote.createdAt)], toSection: .savedQuotes)
        } else {
            snapshot.appendItems([.savedQuote("", Date())], toSection: .savedQuotes)
        }

        // 찍은 사진 - 실제 데이터로 업데이트
        if let photos = photos {
            let images = photos.compactMap { ImageStorageManager.shared.loadImage(fromPath: $0.localImagePath) }
            let photoItem: Item = images.isEmpty ? .photoPage(nil) : .photoPage(images.first)
            snapshot.appendItems([photoItem], toSection: .photoPages)
        } else {
            // 사진 데이터가 제공되지 않은 경우 별도로 로드
            loadPhotosForSnapshot(snapshot: snapshot)
            return
        }

        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func loadPhotosForSnapshot(snapshot: Snapshot) {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)

        do {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            let photoArray = Array(photos)
            
            var updatedSnapshot = snapshot
            let images = photoArray.compactMap { ImageStorageManager.shared.loadImage(fromPath: $0.localImagePath) }
            let photoItem: Item = images.isEmpty ? .photoPage(nil) : .photoPage(images.first)
            
            // 기존 photoPages 섹션 업데이트
            updatedSnapshot.deleteItems(updatedSnapshot.itemIdentifiers(inSection: .photoPages))
            updatedSnapshot.appendItems([photoItem], toSection: .photoPages)
            
            dataSource.apply(updatedSnapshot, animatingDifferences: true)
        } catch {
            print("❌ Failed to load photos for snapshot: \(error.localizedDescription)")
        }
    }
    
    private func showPhotoContextMenu(for imageView: UIImageView, with image: UIImage) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 사진 보기
        alert.addAction(UIAlertAction(title: NSLocalizedString("photo.view", comment: "View photo action"), style: .default) { _ in
            self.showImagePreview(image)
        })
        
        // 사진 저장 (사진 앱으로)
        alert.addAction(UIAlertAction(title: NSLocalizedString("photo.save_to_gallery", comment: "Save to gallery action"), style: .default) { _ in
            self.saveImageToPhotoLibrary(image)
        })
        
        // 사진 삭제
        alert.addAction(UIAlertAction(title: NSLocalizedString("action.delete", comment: "Delete action"), style: .destructive) { _ in
            self.showDeletePhotoConfirmation(for: image)
        })
        
        // 취소
        alert.addAction(UIAlertAction(title: NSLocalizedString("action.cancel", comment: "Cancel action"), style: .cancel))
        
        // iPad 지원
        if let popover = alert.popoverPresentationController {
            popover.sourceView = imageView
            popover.sourceRect = imageView.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showImagePreview(_ image: UIImage) {
        let previewVC = UIViewController()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        
        previewVC.view = imageView
        previewVC.modalPresentationStyle = .fullScreen
        
        // 탭해서 닫기 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissImagePreview))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)
        
        present(previewVC, animated: true)
    }
    
    @objc private func dismissImagePreview() {
        dismiss(animated: true)
    }
    
    private func saveImageToPhotoLibrary(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func imageSaveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert = UIAlertController(
            title: error == nil ? NSLocalizedString("photo.save_success.title", comment: "Save success title") : NSLocalizedString("photo.save_failure.title", comment: "Save failure title"),
            message: error == nil ? NSLocalizedString("photo.save_success.message", comment: "Save success message") : NSLocalizedString("photo.save_failure.message", comment: "Save failure message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("action.confirm", comment: "Confirm action"), style: .default))
        present(alert, animated: true)
    }
    
    private func showDeletePhotoConfirmation(for image: UIImage) {
        let alert = UIAlertController(
            title: NSLocalizedString("photo.delete_confirmation.title", comment: "Delete photo confirmation title"),
            message: NSLocalizedString("photo.delete_confirmation.message", comment: "Delete photo confirmation message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("action.delete", comment: "Delete action"), style: .destructive) { [weak self] _ in
            self?.deletePhoto(image)
        })
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("action.cancel", comment: "Cancel action"), style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func deletePhoto(_ image: UIImage) {
        guard let reactor = reactor else { return }
        let bookId = String(describing: reactor.currentState.book.id)
        
        do {
            let realm = try Realm()
            let photos = realm.objects(RealmPhoto.self).filter("bookId == %@", bookId)
            
            // 삭제할 사진 찾기 (이미지 데이터 비교)
            var photoToDelete: RealmPhoto?
            for photo in photos {
                if let loadedImage = ImageStorageManager.shared.loadImage(fromPath: photo.localImagePath),
                   loadedImage.pngData() == image.pngData() {
                    photoToDelete = photo
                    break
                }
            }
            
            guard let targetPhoto = photoToDelete else { return }
            
            // Realm에서 삭제
            try realm.write {
                realm.delete(targetPhoto)
            }
            
            // 로컬 파일 삭제
            ImageStorageManager.shared.deleteImage(atPath: targetPhoto.localImagePath)
            
            print("✅ Photo deleted successfully")
            loadPhotosAndUpdateUI()
        } catch {
            print("❌ Failed to delete photo: \(error.localizedDescription)")
        }
    }
}

// MARK: - CameraViewController Delegate
extension BookDetailViewController: CameraViewControllerDelegate {
    func cameraViewController(_ controller: CameraViewController, didCapturePhoto image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            self?.savePhoto(image)
        }
    }
    
    func cameraViewControllerDidCancel(_ controller: CameraViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Child Coordinator Management
extension BookDetailViewController {
    private func addChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    private func removeChildCoordinator(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
}
