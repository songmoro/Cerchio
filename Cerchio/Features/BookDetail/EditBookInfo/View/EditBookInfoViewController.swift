//
//  EditBookInfoViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import SnapKit
import ReactorKit
import RxCocoa
import Kingfisher

final class EditBookInfoViewController: BaseViewController<EditBookInfoReactor>, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Callbacks
    var onDismiss: ((Bool) -> Void)? // Bool: isSaved

    // MARK: - UI Components

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let coverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()

    private let changeCoverButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: .`edit_book.change_cover`)
        config.baseForegroundColor = .systemBlue
        let button = UIButton(configuration: config)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .`edit_book.book_title`)
        label.font = UIFont.custom(weight: .semiBold, size: 16)
        label.textColor = .label
        return label
    }()

    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.font = UIFont.custom(weight: .regular, size: 16)
        return textField
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .`edit_book.author`)
        label.font = UIFont.custom(weight: .semiBold, size: 16)
        label.textColor = .label
        return label
    }()

    private let authorTextField: UITextField = {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.font = UIFont.custom(weight: .regular, size: 16)
        return textField
    }()

    private let resetButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: .`edit_book.reset_custom_info`)
        config.baseForegroundColor = .systemRed
        let button = UIButton(configuration: config)
        return button
    }()

    // MARK: - Setup

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [coverImageView, changeCoverButton, titleLabel, titleTextField, authorLabel, authorTextField, resetButton].forEach {
            contentView.addSubview($0)
        }

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        coverImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(24)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(120)
            $0.height.equalTo(160)
        }

        changeCoverButton.snp.makeConstraints {
            $0.top.equalTo(coverImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(changeCoverButton.snp.bottom).offset(32)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        titleTextField.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(44)
        }

        authorLabel.snp.makeConstraints {
            $0.top.equalTo(titleTextField.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }

        authorTextField.snp.makeConstraints {
            $0.top.equalTo(authorLabel.snp.bottom).offset(8)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
            $0.height.equalTo(44)
        }

        resetButton.snp.makeConstraints {
            $0.top.equalTo(authorTextField.snp.bottom).offset(32)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-24)
        }

        setupNavigationBar()
    }

    private func setupNavigationBar() {
        title = String(localized: .`edit_book.title`)

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: String(localized: .`action.cancel`),
            style: .plain,
            target: nil,
            action: nil
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: String(localized: .`action.save`),
            style: .done,
            target: nil,
            action: nil
        )
    }

    // MARK: - Binding

    override func bind(reactor: EditBookInfoReactor) {
        // Action
        navigationItem.leftBarButtonItem?.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.onDismiss?(false)
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

        navigationItem.rightBarButtonItem?.rx.tap
            .map { Reactor.Action.save }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        titleTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { Reactor.Action.updateTitle($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        authorTextField.rx.text.orEmpty
            .distinctUntilChanged()
            .map { Reactor.Action.updateAuthor($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        resetButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showResetConfirmation()
            })
            .disposed(by: disposeBag)

        changeCoverButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showImagePicker()
            })
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.book }
            .take(1)
            .asDriver(onErrorJustReturn: reactor.currentState.book)
            .drive(onNext: { [weak self] book in
                self?.loadInitialCoverImage(book: book)
                self?.titleTextField.placeholder = book.originalCleanTitle
                self?.authorTextField.placeholder = book.author
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.customCoverImagePath }
            .distinctUntilChanged()
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [weak self] imagePath in
                self?.loadLocalCoverImage(path: imagePath)
            })
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.customTitle }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(titleTextField.rx.text)
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.customAuthor }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(authorTextField.rx.text)
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.isSaveSuccess }
            .distinctUntilChanged()
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] _ in
                self?.onDismiss?(true)
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }

    private func loadInitialCoverImage(book: Book) {
        // 커스텀 커버가 있으면 로컬 이미지 로드, 없으면 원본 URL 로드
        if let customCoverPath = book.customCoverImagePath {
            loadLocalCoverImage(path: customCoverPath)
        } else {
            guard let imageURL = URL(string: book.displayImage) else { return }
            coverImageView.kf.setImage(with: imageURL, placeholder: UIImage(systemName: "book.closed"))
        }
    }

    private func loadLocalCoverImage(path: String) {
        if let image = ImageStorageManager.shared.loadImage(fromPath: path) {
            coverImageView.image = image
        } else {
            print("❌ Failed to load local cover image: \(path)")
        }
    }

    private func showResetConfirmation() {
        let alert = UIAlertController(
            title: String(localized: .`edit_book.reset_confirmation_title`),
            message: String(localized: .`edit_book.reset_confirmation_message`),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: .`edit_book.reset`), style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.reset)
        })

        present(alert, animated: true)
    }

    // MARK: - Image Picker

    private func showImagePicker() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "사진 촬영", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .camera)
        })

        alert.addAction(UIAlertAction(title: "앨범에서 선택", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })

        alert.addAction(UIAlertAction(title: String(localized: .`action.cancel`), style: .cancel))

        present(alert, animated: true)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("❌ Source type not available: \(sourceType)")
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = true

        present(picker, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            print("❌ Failed to get image from picker")
            return
        }

        // 이미지 저장
        let imageName = UUID().uuidString
        if let imagePath = ImageStorageManager.shared.saveImage(selectedImage, withName: imageName) {
            // 커버 이미지뷰 즉시 업데이트
            coverImageView.image = selectedImage

            // Reactor에 경로 전달
            reactor?.action.onNext(.updateCoverImage(imagePath))
            print("✅ Cover image saved: \(imagePath)")
        } else {
            print("❌ Failed to save cover image")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
