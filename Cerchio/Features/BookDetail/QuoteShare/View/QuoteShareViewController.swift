//
//  QuoteShareViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/12/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ReactorKit

final class QuoteShareViewController: BaseViewController<QuoteShareReactor> {
    // MARK: - Properties
    private let imageExportedRelay = PublishRelay<UIImage>()
    var imageExported: Observable<UIImage> { imageExportedRelay.asObservable() }

    private var settingsViewController: QuoteShareSettingsViewController?

    // Navigation buttons
    private let dismissButton = UIBarButtonItem(
        image: UIImage(systemName: "chevron.left"),
        style: .plain,
        target: nil,
        action: nil
    )

    private let saveButton = UIBarButtonItem(
        title: "저장",
        style: .done,
        target: nil,
        action: nil
    )

    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .systemBackground
        return scrollView
    }()

    private let contentView = UIView()

    // Preview Container (will be exported as image)
    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.clipsToBounds = true
        return view
    }()

    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        return imageView
    }()

    private lazy var blurEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.alpha = 0
        return effectView
    }()

    private let blurColorView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.alpha = 0
        return view
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.85)
        return view
    }()

    private let bookCoverImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.1
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowRadius = 4
        return imageView
    }()

    private let bookInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 14)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 18)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private let metadataContainerView = UIView()

    private let metadataStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 12)
        label.textColor = .tertiaryLabel
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 12)
        label.textColor = .tertiaryLabel
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "문장 공유"
        setupNavigationBar()
    }

    // MARK: - Setup
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(previewContainer)

        // Preview container subviews
        previewContainer.addSubview(backgroundImageView)
        backgroundImageView.addSubview(blurEffectView)
        previewContainer.addSubview(blurColorView)
        previewContainer.addSubview(overlayView)
        previewContainer.addSubview(bookCoverImageView)
        previewContainer.addSubview(quoteLabel)
        previewContainer.addSubview(metadataContainerView)

        metadataContainerView.addSubview(bookInfoLabel)
        metadataContainerView.addSubview(metadataStackView)

        metadataStackView.addArrangedSubview(pageLabel)
        metadataStackView.addArrangedSubview(dateLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        previewContainer.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(500)
        }

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        blurEffectView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        blurColorView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        bookCoverImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.centerX.equalToSuperview()
            $0.width.equalToSuperview().multipliedBy(0.7)
            $0.height.equalToSuperview(\.snp.width).multipliedBy(0.7)
        }
        
        quoteLabel.snp.makeConstraints {
            $0.top.equalTo(bookCoverImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        metadataContainerView.snp.makeConstraints {
            $0.top.equalTo(quoteLabel.snp.bottom).offset(20)
            $0.horizontalEdges.equalToSuperview().inset(32)
            $0.bottom.lessThanOrEqualToSuperview().inset(32)
        }

        bookInfoLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(metadataStackView.snp.leading).offset(-8)
            $0.bottom.lessThanOrEqualToSuperview()
        }

        metadataStackView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }

        previewContainer.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = dismissButton
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupSettingsBottomSheet(config: QuoteBackgroundConfig) {
        let settingsVC = QuoteShareSettingsViewController(config: config)
        settingsVC.delegate = self
        self.settingsViewController = settingsVC

        addChild(settingsVC)
        view.addSubview(settingsVC.view)
        settingsVC.didMove(toParent: self)

        settingsVC.view.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.height.equalTo(450)
        }
    }

    private func configureContent(with quoteData: QuoteShareData) {
        // Configure book info
        loadBookCoverImage(from: quoteData)
        updateBookInfo(title: quoteData.bookTitle, author: quoteData.bookAuthor)

        // Configure quote
        quoteLabel.text = "\"\(quoteData.quote)\""

        // Configure metadata
        updateMetadata(pageNumber: quoteData.pageNumber, date: quoteData.date)
    }

    private func updateBookInfo(title: String, author: String) {
        bookInfoLabel.text = "\(title)\n\(author)"
    }

    private func updateMetadata(pageNumber: Int?, date: Date) {
        // Page number
        if let pageNumber = pageNumber {
            pageLabel.text = "p.\(pageNumber)"
            pageLabel.isHidden = false
        } else {
            pageLabel.isHidden = true
        }

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: date)
    }

    private func loadBookCoverImage(from quoteData: QuoteShareData) {
        // Use pre-loaded image if available
        if let coverImage = quoteData.bookCoverImage {
            bookCoverImageView.image = coverImage
            backgroundImageView.image = coverImage
            return
        }

        // Load from URL
        guard let urlString = quoteData.bookCoverImageURL,
              let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else { return }

            DispatchQueue.main.async {
                self?.bookCoverImageView.image = image
                self?.backgroundImageView.image = image
            }
        }.resume()
    }

    // MARK: - Binding
    override func bind(reactor: QuoteShareReactor) {
        // Action
        dismissButton.rx.tap
            .map { Reactor.Action.dismissTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        saveButton.rx.tap
            .map { Reactor.Action.saveTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State - Initial setup
        reactor.state.map { $0.quoteData }
            .take(1)
            .asDriver(onErrorJustReturn: reactor.currentState.quoteData)
            .drive(onNext: { [weak self] quoteData in
                self?.configureContent(with: quoteData)
            })
            .disposed(by: disposeBag)

        reactor.state.map { $0.backgroundConfig }
            .take(1)
            .asDriver(onErrorJustReturn: reactor.currentState.backgroundConfig)
            .drive(onNext: { [weak self] config in
                self?.setupSettingsBottomSheet(config: config)
            })
            .disposed(by: disposeBag)

        // State - Background config changes
        reactor.state.map { $0.backgroundConfig }
            .distinctUntilChanged { $0.isEnabled == $1.isEnabled }
            .skip(1)
            .asDriver(onErrorJustReturn: reactor.currentState.backgroundConfig)
            .drive(onNext: { [weak self] config in
                self?.updateBackgroundVisibility(config.isEnabled)
            })
            .disposed(by: disposeBag)

        // Blur
        let blurConfig = reactor.state.map { ($0.backgroundConfig.isBlurEnabled, $0.backgroundConfig.blurIntensity) }
        blurConfig
            .distinctUntilChanged { prev, next in prev.0 == next.0 && prev.1 == next.1 }
            .skip(1)
            .asDriver(onErrorJustReturn: (false, 0.5))
            .drive(onNext: { [weak self] tuple in
                self?.updateBlur(isEnabled: tuple.0, intensity: tuple.1)
            })
            .disposed(by: disposeBag)

        // Opacity
        let opacityConfig = reactor.state.map { ($0.backgroundConfig.isOpacityEnabled, $0.backgroundConfig.imageOpacity) }
        opacityConfig
            .distinctUntilChanged { prev, next in prev.0 == next.0 && prev.1 == next.1 }
            .skip(1)
            .asDriver(onErrorJustReturn: (false, 1.0))
            .drive(onNext: { [weak self] tuple in
                self?.updateOpacity(isEnabled: tuple.0, opacity: tuple.1)
            })
            .disposed(by: disposeBag)

        // Scale
        let scaleConfig = reactor.state.map { ($0.backgroundConfig.isScaleEnabled, $0.backgroundConfig.imageScale) }
        scaleConfig
            .distinctUntilChanged { prev, next in prev.0 == next.0 && prev.1 == next.1 }
            .skip(1)
            .asDriver(onErrorJustReturn: (false, 1.0))
            .drive(onNext: { [weak self] tuple in
                self?.updateScale(isEnabled: tuple.0, scale: tuple.1)
            })
            .disposed(by: disposeBag)

        // Blur Color
        let blurColorConfig = reactor.state.map { ($0.backgroundConfig.isBlurColorEnabled, $0.backgroundConfig.blurColor, $0.backgroundConfig.blurColorOpacity) }
        blurColorConfig
            .distinctUntilChanged { prev, next in prev.0 == next.0 && prev.1 == next.1 && prev.2 == next.2 }
            .skip(1)
            .asDriver(onErrorJustReturn: (false, .white, 0.3))
            .drive(onNext: { [weak self] tuple in
                self?.updateBlurColor(isEnabled: tuple.0, color: tuple.1, opacity: tuple.2)
            })
            .disposed(by: disposeBag)

        // Metadata Visibility
        let metadataConfig = reactor.state.map { ($0.backgroundConfig.showBookInfo, $0.backgroundConfig.showPageNumber, $0.backgroundConfig.showDate) }
        metadataConfig
            .distinctUntilChanged { prev, next in prev.0 == next.0 && prev.1 == next.1 && prev.2 == next.2 }
            .skip(1)
            .asDriver(onErrorJustReturn: (true, true, true))
            .drive(onNext: { [weak self] tuple in
                self?.updateMetadataVisibility(showBookInfo: tuple.0, showPageNumber: tuple.1, showDate: tuple.2)
            })
            .disposed(by: disposeBag)

        // State - Export image
        reactor.state.map { $0.shouldExportImage }
            .distinctUntilChanged()
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] _ in
                self?.exportImage()
            })
            .disposed(by: disposeBag)

        // State - Dismiss
        reactor.state.map { $0.shouldDismiss }
            .distinctUntilChanged()
            .filter { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] _ in
                self?.navigationEvents.accept(.close)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Private Methods
    private func updateBackgroundVisibility(_ isVisible: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.backgroundImageView.alpha = isVisible ? 1.0 : 0.0
            self.blurEffectView.alpha = isVisible ? 1.0 : 0.0
        }
    }

    private func updateBlur(isEnabled: Bool, intensity: CGFloat) {
        guard let reactor = reactor, reactor.currentState.backgroundConfig.isEnabled else { return }

        UIView.animate(withDuration: 0.3) {
            if isEnabled {
                // Use UIBlurEffect for real-time preview
                let blurStyle: UIBlurEffect.Style
                if intensity < 0.33 {
                    blurStyle = .extraLight
                } else if intensity < 0.66 {
                    blurStyle = .light
                } else {
                    blurStyle = .regular
                }
                self.blurEffectView.effect = UIBlurEffect(style: blurStyle)
                self.blurEffectView.alpha = 1.0
            } else {
                self.blurEffectView.alpha = 0.0
            }
        }
    }

    private func updateOpacity(isEnabled: Bool, opacity: CGFloat) {
        guard let reactor = reactor, reactor.currentState.backgroundConfig.isEnabled else { return }

        UIView.animate(withDuration: 0.3) {
            if isEnabled {
                self.backgroundImageView.alpha = opacity
            } else {
                self.backgroundImageView.alpha = 1.0
            }
        }
    }

    private func updateScale(isEnabled: Bool, scale: CGFloat) {
        guard let reactor = reactor, reactor.currentState.backgroundConfig.isEnabled else { return }

        UIView.animate(withDuration: 0.3) {
            if isEnabled {
                self.backgroundImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
            } else {
                self.backgroundImageView.transform = .identity
            }
        }
    }

    private func updateBlurColor(isEnabled: Bool, color: UIColor, opacity: CGFloat) {
        guard let reactor = reactor, reactor.currentState.backgroundConfig.isEnabled else { return }

        UIView.animate(withDuration: 0.3) {
            if isEnabled {
                self.blurColorView.backgroundColor = color
                self.blurColorView.alpha = opacity
            } else {
                self.blurColorView.alpha = 0.0
            }
        }
    }

    private func updateMetadataVisibility(showBookInfo: Bool, showPageNumber: Bool, showDate: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.bookInfoLabel.isHidden = !showBookInfo
            self.pageLabel.isHidden = !showPageNumber
            self.dateLabel.isHidden = !showDate
        }
    }

//    // MARK: - Old blur implementation (commented out)
//    private func applyBlurEffect() {
//        guard let reactor = reactor,
//              reactor.currentState.backgroundConfig.isEnabled,
//              let originalImage = reactor.currentState.quoteData.bookCoverImage else { return }
//
//        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            guard let self = self,
//                  let reactor = self.reactor else { return }
//
//            let blurEffect = BlurImageEffect(intensity: reactor.currentState.backgroundConfig.blurIntensity)
//            let blurredImage = blurEffect.apply(to: originalImage)
//
//            DispatchQueue.main.async {
//                self.backgroundImageView.image = blurredImage
//            }
//        }
//    }

    private func exportImage() {
        guard let reactor = reactor else { return }

        // Show loading indicator
        let loadingAlert = UIAlertController(title: nil, message: "이미지 생성 중...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        loadingIndicator.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: loadingAlert.view.bottomAnchor, constant: -20).isActive = true
        present(loadingAlert, animated: true)

        // Capture image on main thread (UI operations must be on main thread)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }

            // Capture the current view hierarchy as-is
            // UIVisualEffectView will be captured correctly with drawHierarchy
            let renderer = UIGraphicsImageRenderer(bounds: self.previewContainer.bounds)
            let capturedImage = renderer.image { context in
                self.previewContainer.drawHierarchy(in: self.previewContainer.bounds, afterScreenUpdates: true)
            }

            // Save to photo library only
            UIImageWriteToSavedPhotosAlbum(capturedImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // Dismiss loading alert first
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            if let error = error {
                // Show error alert
                let errorAlert = UIAlertController(
                    title: "저장 실패",
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(errorAlert, animated: true)
            } else {
                // Show success alert
                let successAlert = UIAlertController(
                    title: "저장 완료",
                    message: "이미지가 사진 라이브러리에 저장되었습니다.",
                    preferredStyle: .alert
                )
                successAlert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
                    // Dismiss the quote share screen after successful save
                    self?.navigationEvents.accept(.close)
                })
                self.present(successAlert, animated: true)
            }
        }
    }
}

// MARK: - QuoteShareSettingsDelegate
extension QuoteShareViewController: QuoteShareSettingsDelegate {
    func settingsDidChangeBackground(isEnabled: Bool) {
        reactor?.action.onNext(.backgroundToggled(isEnabled))
    }

    func settingsDidChangeBlur(isEnabled: Bool, intensity: CGFloat) {
        reactor?.action.onNext(.blurChanged(isEnabled: isEnabled, intensity: intensity))
    }

    func settingsDidChangeBlurColor(isEnabled: Bool, color: UIColor, opacity: CGFloat) {
        reactor?.action.onNext(.blurColorChanged(isEnabled: isEnabled, color: color, opacity: opacity))
    }

    func settingsDidChangeOpacity(isEnabled: Bool, opacity: CGFloat) {
        reactor?.action.onNext(.opacityChanged(isEnabled: isEnabled, opacity: opacity))
    }

    func settingsDidChangeScale(isEnabled: Bool, scale: CGFloat) {
        reactor?.action.onNext(.scaleChanged(isEnabled: isEnabled, scale: scale))
    }

    func settingsDidChangeMetadataVisibility(showBookInfo: Bool, showPageNumber: Bool, showDate: Bool) {
        reactor?.action.onNext(.metadataVisibilityChanged(showBookInfo: showBookInfo, showPageNumber: showPageNumber, showDate: showDate))
    }
}
