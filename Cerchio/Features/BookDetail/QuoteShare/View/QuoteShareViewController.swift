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

    private let bookTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .bold, size: 20)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    private let bookAuthorLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 16)
        label.textColor = .secondaryLabel
        return label
    }()

    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        return view
    }()

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 18)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

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
        previewContainer.addSubview(overlayView)
        previewContainer.addSubview(bookCoverImageView)
        previewContainer.addSubview(bookTitleLabel)
        previewContainer.addSubview(bookAuthorLabel)
        previewContainer.addSubview(dividerView)
        previewContainer.addSubview(quoteLabel)
        previewContainer.addSubview(metadataStackView)

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
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(500)
        }

        backgroundImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        overlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        bookCoverImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(32)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(80)
            $0.height.equalTo(120)
        }

        bookTitleLabel.snp.makeConstraints {
            $0.top.equalTo(bookCoverImageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        bookAuthorLabel.snp.makeConstraints {
            $0.top.equalTo(bookTitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        dividerView.snp.makeConstraints {
            $0.top.equalTo(bookAuthorLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(32)
            $0.height.equalTo(1)
        }

        quoteLabel.snp.makeConstraints {
            $0.top.equalTo(dividerView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(32)
        }

        metadataStackView.snp.makeConstraints {
            $0.top.equalTo(quoteLabel.snp.bottom).offset(16)
            $0.leading.greaterThanOrEqualToSuperview().inset(32)
            $0.trailing.equalToSuperview().inset(32)
            $0.bottom.lessThanOrEqualToSuperview().inset(32)
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
        let settingsVC = QuoteShareSettingsViewController(
            isBackgroundEnabled: config.isEnabled,
            blurIntensity: config.blurIntensity
        )
        settingsVC.delegate = self
        self.settingsViewController = settingsVC

        addChild(settingsVC)
        view.addSubview(settingsVC.view)
        settingsVC.didMove(toParent: self)

        settingsVC.view.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(220)
        }
    }

    private func configureContent(with quoteData: QuoteShareData) {
        // Configure book info
        loadBookCoverImage(from: quoteData)
        bookTitleLabel.text = quoteData.bookTitle
        bookAuthorLabel.text = quoteData.bookAuthor

        // Configure quote
        quoteLabel.text = "\"\(quoteData.quote)\""

        // Configure metadata
        if let pageNumber = quoteData.pageNumber {
            pageLabel.text = "p.\(pageNumber)"
        } else {
            pageLabel.isHidden = true
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: quoteData.date)
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

        reactor.state.map { $0.backgroundConfig }
            .distinctUntilChanged { $0.blurIntensity == $1.blurIntensity }
            .skip(1)
            .asDriver(onErrorJustReturn: reactor.currentState.backgroundConfig)
            .drive(onNext: { [weak self] config in
                self?.updateBlurIntensity(config.blurIntensity)
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
        }

        if isVisible {
            applyBlurEffect()
        }
    }

    private func updateBlurIntensity(_ intensity: CGFloat) {
        applyBlurEffect()
    }

    private func applyBlurEffect() {
        guard let reactor = reactor,
              reactor.currentState.backgroundConfig.isEnabled,
              let originalImage = reactor.currentState.quoteData.bookCoverImage else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let reactor = self.reactor else { return }

            let blurEffect = BlurImageEffect(intensity: reactor.currentState.backgroundConfig.blurIntensity)
            let blurredImage = blurEffect.apply(to: originalImage)

            DispatchQueue.main.async {
                self.backgroundImageView.image = blurredImage
            }
        }
    }

    private func exportImage() {
        // Capture preview container as image
        let renderer = UIGraphicsImageRenderer(bounds: previewContainer.bounds)
        let image = renderer.image { context in
            previewContainer.layer.render(in: context.cgContext)
        }

        imageExportedRelay.accept(image)

        // Show success message
        let alert = UIAlertController(
            title: "저장 완료",
            message: "이미지가 생성되었습니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - QuoteShareSettingsDelegate
extension QuoteShareViewController: QuoteShareSettingsDelegate {
    func settingsDidChangeBackground(isEnabled: Bool) {
        reactor?.action.onNext(.backgroundToggled(isEnabled))
    }

    func settingsDidChangeBlur(intensity: CGFloat) {
        reactor?.action.onNext(.blurIntensityChanged(intensity))
    }
}
