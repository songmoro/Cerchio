//
//  PhotoListViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class PhotoListViewController: ListViewBaseViewController<PhotoListReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Photo>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Photo>

    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var dataSource: DataSource!

    var onAddPhotoTapped: (() -> Void)?
    var onPhotosDeleted: (() -> Void)?
    private var selectedPhotoIds: Set<String> = []
    private var service: PhotoListService?

    private var photoImages: [String: UIImage] = [:]
    private let imageQueue = DispatchQueue(label: "com.cerchio.photoList.imageQueue", attributes: .concurrent)

    private var cancelButton: UIBarButtonItem!
    private var selectAllButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!

    override var viewTitle: String {
        return String(localized: .bookDetailPhotos)
    }

    nonisolated enum Section: CaseIterable {
        case photos
    }

    func setService(_ service: PhotoListService) {
        self.service = service
    }

    override func addButtonTapped() {
        onAddPhotoTapped?()
    }

    override func editModeDidChange(_ isEditMode: Bool) {
        if isEditMode {
            enterEditMode()
        } else {
            exitEditMode()
        }
    }

    override func setupUI() {
        super.setupUI()
        setupBackButton()
        setupEditModeButtons()
        setupCollectionView()
        setupLayout()
        configureDataSource()
        setupRxBindings()
    }

    private func setupBackButton() {
        navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent {
            imageQueue.async(flags: .barrier) { [weak self] in
                self?.photoImages.removeAll()
            }
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1/3)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(2)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 2
        section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupEditModeButtons() {
        cancelButton = UIBarButtonItem(
            title: String(localized: .actionCancel),
            style: .plain,
            target: nil,
            action: nil
        )

        selectAllButton = UIBarButtonItem(
            title: String(localized: .actionSelectAll),
            style: .plain,
            target: nil,
            action: nil
        )

        deleteButton = UIBarButtonItem(
            title: String(localized: .actionDelete),
            style: .plain,
            target: nil,
            action: nil
        )
        deleteButton.tintColor = .systemRed

        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.isEditMode = false
            })
            .disposed(by: disposeBag)

        selectAllButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.selectAllPhotos()
            })
            .disposed(by: disposeBag)

        deleteButton.rx.tap
            .do(onNext: { HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] in
                self?.deleteSelectedPhotos()
            })
            .disposed(by: disposeBag)
    }

    private func updateNavigationBar() {
        if isEditMode {
            if selectedPhotoIds.isEmpty {
                navigationItem.leftBarButtonItem = cancelButton
                navigationItem.rightBarButtonItems = [selectAllButton]
            } else {
                navigationItem.leftBarButtonItem = cancelButton
                navigationItem.rightBarButtonItems = [deleteButton]
            }
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.allowsMultipleSelection = true
        collectionView.register(PhotoGridCell.self, forCellWithReuseIdentifier: PhotoGridCell.identifier)

        view.addSubview(collectionView)
    }

    private func setupRxBindings() {
        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == false }
            .do(onNext: { _ in HapticFeedbackManager.shared.impact() })
            .subscribe(onNext: { [weak self] photo in
                guard let self = self else { return }
                if let indexPath = self.dataSource.indexPath(for: photo) {
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }

                let image = self.imageQueue.sync {
                    self.photoImages[photo.id]
                }

                if let image = image {
                    self.showImagePreview(image)
                }
            })
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] photo in
                guard let self = self else { return }

                if self.selectedPhotoIds.contains(photo.id) {
                    if let indexPath = self.dataSource.indexPath(for: photo) {
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                    }
                } else {
                    self.selectedPhotoIds.insert(photo.id)
                    self.updateNavigationBar()
                }
            })
            .disposed(by: disposeBag)

        collectionView.rx.itemDeselected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] photo in
                guard let self = self else { return }
                self.selectedPhotoIds.remove(photo.id)
                self.updateNavigationBar()
            })
            .disposed(by: disposeBag)
    }

    private func setupLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, photo in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridCell.identifier, for: indexPath) as! PhotoGridCell

            let photoId = photo.id

            let image = self?.imageQueue.sync {
                self?.photoImages[photoId]
            }

            if let image = image {
                cell.configure(with: image)
            } else {
                cell.configure(with: nil)
            }

            return cell
        }
    }

    override func bind(reactor: PhotoListReactor) {
        Observable.just(PhotoListReactor.Action.loadPhotos)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.photos }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] photos in
                self?.loadPhotosAndUpdateSnapshot(with: photos)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { isLoading in
            })
            .disposed(by: disposeBag)
    }

    private func updateSnapshot(with photos: [Photo]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.photos])
        snapshot.appendItems(photos, toSection: .photos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func loadPhotosAndUpdateSnapshot(with photos: [Photo]) {
        updateSnapshot(with: photos)

        Task { [weak self] in
            guard let self = self else { return }

            await withTaskGroup(of: (String, UIImage?).self) { group in
                for photo in photos {
                    group.addTask {
                        let image = await ImageStorageManager.shared.loadImage(fromPath: photo.localImagePath)
                        return (photo.id, image)
                    }
                }

                for await (photoId, image) in group {
                    guard let image = image else { continue }

                    self.imageQueue.async(flags: .barrier) { [weak self] in
                        self?.photoImages[photoId] = image
                    }
                }
            }

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                var snapshot = self.dataSource.snapshot()
                let allItems = snapshot.itemIdentifiers
                if #available(iOS 15.0, *) {
                    snapshot.reconfigureItems(allItems)
                } else {
                    snapshot.reloadItems(allItems)
                }
                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
    }

    private func selectAllPhotos() {
        guard let reactor = reactor else { return }
        let photos = reactor.currentState.photos

        for (index, photo) in photos.enumerated() {
            selectedPhotoIds.insert(photo.id)
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        updateNavigationBar()
    }

    private func enterEditMode() {
        isEditMode = true
        selectedPhotoIds.removeAll()

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        updateNavigationBar()
    }

    private func exitEditMode() {
        isEditMode = false
        selectedPhotoIds.removeAll()

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }

        updateNavigationBar()
    }

    private func deleteSelectedPhotos() {
        guard !selectedPhotoIds.isEmpty else { return }

        let alert = UIAlertController(
            title: String(localized: .actionDelete),
            message: "선택한 \(selectedPhotoIds.count)개의 사진을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionCancel), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .actionDelete), style: .destructive) { [weak self] _ in
            self?.performDeletion()
        })

        present(alert, animated: true)
    }

    private func performDeletion() {
        let photoIdsToDelete = Array(selectedPhotoIds)

        for photoId in photoIdsToDelete {
            reactor?.action.onNext(.deletePhoto(photoId))
        }

        exitEditMode()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onPhotosDeleted?()
    }
}

extension PhotoListViewController {
    private func showImagePreview(_ image: UIImage) {
        let previewVC = UIViewController()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black

        previewVC.view = imageView
        previewVC.modalPresentationStyle = .fullScreen

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissImagePreview))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapGesture)

        present(previewVC, animated: true)
    }

    @objc private func dismissImagePreview() {
        dismiss(animated: true)
    }
}

final class PhotoGridCell: UICollectionViewCell {
    static let identifier = "PhotoGridCell"

    private let imageView = UIImageView()
    private let selectionOverlay = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        selectionOverlay.backgroundColor = UIColor.forestGreen.withAlphaComponent(0.3)
        selectionOverlay.isHidden = true
        contentView.addSubview(selectionOverlay)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(with image: UIImage?) {
        imageView.image = image
    }

    override var isSelected: Bool {
        didSet {
            selectionOverlay.isHidden = !isSelected
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        isSelected = false
    }
}
