//
//  PhotoListViewController.swift
//  Cerchio
//
//  Created by Claude on 10/1/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class PhotoListViewController: BaseViewController<PhotoListReactor> {
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Photo>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Photo>

    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var dataSource: DataSource!

    // MARK: - Properties
    var onAddPhotoTapped: (() -> Void)?
    var onPhotosDeleted: (() -> Void)?
    private var isEditMode: Bool = false
    private var selectedPhotoIds: Set<String> = []

    // Navigation bar buttons
    private var addButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!
    private var cancelButton: UIBarButtonItem!
    private var selectAllButton: UIBarButtonItem!
    private var deleteButton: UIBarButtonItem!

    // MARK: - Section Type
    nonisolated enum Section: CaseIterable {
        case photos
    }

    // MARK: - Setup
    override func setupUI() {
        super.setupUI()
        setupNavigationBar()
        setupCollectionView()
        setupLayout()
        configureDataSource()
        setupRxBindings()
    }

    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/3),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1/3) // 정사각형 (1:1 비율)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(2)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 2
        section.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func setupNavigationBar() {
        title = String(localized: .bookDetailPhotos)

        // 추가 버튼
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)

        // 편집 버튼
        editButton = UIBarButtonItem(
            title: String(localized: .actionEdit),
            style: .plain,
            target: nil,
            action: nil
        )

        // 취소 버튼
        cancelButton = UIBarButtonItem(
            title: String(localized: .actionCancel),
            style: .plain,
            target: nil,
            action: nil
        )

        // 전체 선택 버튼
        selectAllButton = UIBarButtonItem(
            title: "전체 선택",
            style: .plain,
            target: nil,
            action: nil
        )

        // 삭제 버튼
        deleteButton = UIBarButtonItem(
            title: String(localized: .actionDelete),
            style: .plain,
            target: nil,
            action: nil
        )
        deleteButton.tintColor = .systemRed

        navigationItem.rightBarButtonItems = [addButton, editButton]

        // Rx 바인딩
        setupNavigationBarRx()
    }

    private func setupNavigationBarRx() {
        addButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onAddPhotoTapped?()
            })
            .disposed(by: disposeBag)

        editButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.enterEditMode()
            })
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.exitEditMode()
            })
            .disposed(by: disposeBag)

        selectAllButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.selectAllPhotos()
            })
            .disposed(by: disposeBag)

        deleteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.deleteSelectedPhotos()
            })
            .disposed(by: disposeBag)
    }

    private func updateNavigationBar() {
        if isEditMode {
            // 편집 모드
            if selectedPhotoIds.isEmpty {
                // 선택된 사진이 없으면: [취소] [전체 선택]
                navigationItem.leftBarButtonItem = cancelButton
                navigationItem.rightBarButtonItems = [selectAllButton]
            } else {
                // 선택된 사진이 있으면: [취소] [삭제]
                navigationItem.leftBarButtonItem = cancelButton
                navigationItem.rightBarButtonItems = [deleteButton]
            }
        } else {
            // 일반 모드: [추가] [편집]
            navigationItem.leftBarButtonItem = nil
            navigationItem.rightBarButtonItems = [addButton, editButton]
        }
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.allowsMultipleSelection = true
        collectionView.register(PhotoGridCell.self, forCellWithReuseIdentifier: PhotoGridCell.identifier)

        view.addSubview(collectionView)
    }

    private func setupRxBindings() {
        // Collection View Selection - 일반 모드
        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == false }
            .subscribe(onNext: { [weak self] photo in
                guard let self = self else { return }
                if let indexPath = self.dataSource.indexPath(for: photo) {
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }
                guard let image = ImageStorageManager.shared.loadImage(fromPath: photo.localImagePath) else { return }
                self.showImagePreview(image)
            })
            .disposed(by: disposeBag)

        // Collection View Selection - 편집 모드
        collectionView.rx.itemSelected(dataSource)
            .filter { [weak self] _ in self?.isEditMode == true }
            .subscribe(onNext: { [weak self] photo in
                guard let self = self else { return }

                // 이미 선택된 경우 deselect 처리 (다음 이벤트에서 처리됨)
                if self.selectedPhotoIds.contains(photo.id) {
                    if let indexPath = self.dataSource.indexPath(for: photo) {
                        self.collectionView.deselectItem(at: indexPath, animated: true)
                    }
                } else {
                    // 새로 선택된 경우
                    self.selectedPhotoIds.insert(photo.id)
                    self.updateNavigationBar()
                }
            })
            .disposed(by: disposeBag)

        // Collection View Deselection - 편집 모드
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

            // 백그라운드에서 이미지 로드
            Task {
                let imagePath = photo.localImagePath
                let image = await Task.detached {
                    ImageStorageManager.shared.loadImage(fromPath: imagePath)
                }.value

                // UI 업데이트는 메인 스레드에서
                await MainActor.run {
                    // 셀이 재사용되지 않았는지 확인
                    if let currentCell = collectionView.cellForItem(at: indexPath) as? PhotoGridCell,
                       let image = image {
                        currentCell.configure(with: image)
                    }
                }
            }

            return cell
        }
    }

    override func bind(reactor: PhotoListReactor) {
        // Action
        Observable.just(PhotoListReactor.Action.loadPhotos)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State - Photos (use Driver for UI updates)
        reactor.state
            .map { $0.photos }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(onNext: { [weak self] photos in
                self?.updateSnapshot(with: photos)
            })
            .disposed(by: disposeBag)

        // State - Loading
        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { isLoading in
                print("Loading: \(isLoading)")
            })
            .disposed(by: disposeBag)
    }

    private func updateSnapshot(with photos: [Photo]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.photos])
        snapshot.appendItems(photos, toSection: .photos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    // MARK: - Actions
    private func selectAllPhotos() {
        guard let reactor = reactor else { return }
        let photos = reactor.currentState.photos

        // 모든 사진 선택
        for (index, photo) in photos.enumerated() {
            selectedPhotoIds.insert(photo.id)
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        }

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        updateNavigationBar()
    }

    private func enterEditMode() {
        isEditMode = true
        selectedPhotoIds.removeAll()

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        updateNavigationBar()
    }

    private func exitEditMode() {
        isEditMode = false
        selectedPhotoIds.removeAll()

        // 햅틱 피드백
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // 모든 선택 해제
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

        // 편집 모드 종료
        exitEditMode()

        // 햅틱 피드백
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // 사진이 삭제되었음을 알림
        onPhotosDeleted?()
    }
}

// MARK: - Image Preview
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

// MARK: - PhotoGridCell
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

        selectionOverlay.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        selectionOverlay.isHidden = true
        contentView.addSubview(selectionOverlay)

        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        selectionOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    func configure(with image: UIImage) {
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
