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
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private var dataSource: DataSource!

    // MARK: - Properties
    var onAddPhotoTapped: (() -> Void)?
    private var isEditMode: Bool = false

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
    }

    private func setupNavigationBar() {
        title = String(localized: .bookDetailPhotos)

        // 추가 버튼
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonTapped)
        )

        // 편집 버튼
        let editButton = UIBarButtonItem(
            title: NSLocalizedString("action.edit", comment: "Edit action"),
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )

        navigationItem.rightBarButtonItems = [addButton, editButton]
    }

    private func updateNavigationBar() {
        guard let rightBarButtonItems = navigationItem.rightBarButtonItems,
              rightBarButtonItems.count >= 2 else { return }

        let editButton = rightBarButtonItems[1]

        if isEditMode {
            editButton.title = NSLocalizedString("action.done", comment: "Done action")
            editButton.style = .done
        } else {
            editButton.title = NSLocalizedString("action.edit", comment: "Edit action")
            editButton.style = .plain
        }
    }

    private func setupCollectionView() {
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
        collectionView.register(PhotoGridCell.self, forCellWithReuseIdentifier: PhotoGridCell.identifier)

        view.addSubview(collectionView)
    }

    private func setupLayout() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func configureDataSource() {
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, photo in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoGridCell.identifier, for: indexPath) as! PhotoGridCell

            if let image = ImageStorageManager.shared.loadImage(fromPath: photo.localImagePath) {
                cell.configure(with: image)
            }

            return cell
        }
    }

    override func bind(reactor: PhotoListReactor) {
        // Action
        Observable.just(PhotoListReactor.Action.loadPhotos)
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.photos }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] photos in
                self?.updateSnapshot(with: photos)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isLoading }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { isLoading in
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
    @objc private func addButtonTapped() {
        onAddPhotoTapped?()
    }

    @objc private func editButtonTapped() {
        isEditMode.toggle()
        updateNavigationBar()

        if !isEditMode {
            // 편집 모드 종료 시 선택 해제
            collectionView.indexPathsForSelectedItems?.forEach {
                collectionView.deselectItem(at: $0, animated: true)
            }
        }
    }

    private func deleteSelectedPhotos() {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems,
              !selectedIndexPaths.isEmpty else { return }

        let photosToDelete = selectedIndexPaths.compactMap { dataSource.itemIdentifier(for: $0) }

        for photo in photosToDelete {
            reactor?.action.onNext(.deletePhoto(photo.id))
        }
    }
}

// MARK: - UICollectionViewDelegate
extension PhotoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditMode {
            // 편집 모드에서는 선택 표시만
            return
        } else {
            // 일반 모드에서는 사진 보기
            collectionView.deselectItem(at: indexPath, animated: true)
            guard let photo = dataSource.itemIdentifier(for: indexPath),
                  let image = ImageStorageManager.shared.loadImage(fromPath: photo.localImagePath) else { return }
            showImagePreview(image)
        }
    }

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

// MARK: - UICollectionViewDelegateFlowLayout
extension PhotoListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let spacing = layout.minimumInteritemSpacing
        let insets = layout.sectionInset
        let width = (collectionView.bounds.width - insets.left - insets.right - spacing * 2) / 3
        return CGSize(width: width, height: width)
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
