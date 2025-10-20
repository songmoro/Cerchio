//
//  QuoteSaveViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/30/25.
//

import UIKit
import SnapKit
import RealmSwift
import RxSwift
import RxCocoa
import FirebaseAnalytics

final class QuoteSaveViewController: UIViewController {
    // MARK: - Events
    enum Event {
        case quoteSaved(String)
        case cancelled
    }

    private let eventRelay = PublishRelay<Event>()
    var events: Observable<Event> { eventRelay.asObservable() }

    // MARK: - Properties
    private let bookId: String
    private var quoteRepository: QuoteRepositoryProtocol?
    private let disposeBag = DisposeBag()

    // Edit mode properties
    private var isEditMode: Bool = false
    private var editingQuoteId: String?

    // MARK: - UI Components
    private let textView: InsetTextView = {
        let textView = InsetTextView()
        textView.font = .custom(weight: .regular, size: 16)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.textInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        textView.placeholder = String(localized: .quoteSavePlaceholder)
        return textView
    }()

    private let pageNumberTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = String(localized: .quoteSavePagePlaceholder)
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.clearButtonMode = .whileEditing
        return textField
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .quoteSavePageLabel)
        label.font = .custom(weight: .medium, size: 14)
        label.textColor = .label
        return label
    }()

    // MARK: - Initialization
    init(bookId: String, existingQuote: String? = nil, existingPageNumber: Int? = nil) {
        self.bookId = bookId
        super.init(nibName: nil, bundle: nil)

        // 기존 문장이 있으면 편집 모드로 설정
        if let existingQuote = existingQuote {
            self.isEditMode = true
            // Note: editingQuoteId는 나중에 repository에서 조회하여 설정
            // 여기서는 UI만 미리 설정
            self.preloadedQuote = existingQuote
            self.preloadedPageNumber = existingPageNumber
        }
    }

    // Preloaded data for edit mode
    private var preloadedQuote: String?
    private var preloadedPageNumber: Int?

    func setQuoteRepository(_ repository: QuoteRepositoryProtocol) {
        quoteRepository = repository
    }

    func configureForEdit(quoteId: String, quote: String, pageNumber: Int?) {
        isEditMode = true
        editingQuoteId = quoteId

        // 뷰가 로드된 후에 설정
        loadViewIfNeeded()
        textView.text = quote
        pageNumberTextField.text = pageNumber.map { String($0) }
        updateSaveButtonState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardHandling()
        setupModalBehavior()

        // Preloaded 데이터가 있으면 설정
        if let preloadedQuote = preloadedQuote {
            textView.text = preloadedQuote
            if let pageNumber = preloadedPageNumber {
                pageNumberTextField.text = String(pageNumber)
            }
            updateSaveButtonState()

            // 편집 모드에서는 quoteId 찾기
            loadEditingQuoteId(quote: preloadedQuote)
        }

        // 자동으로 텍스트뷰에 포커스
        textView.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 확실하게 modal presentation 설정
        isModalInPresentation = true
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(textView)
        view.addSubview(pageLabel)
        view.addSubview(pageNumberTextField)

        setupConstraints()
        setupTextView()
    }

    private func setupConstraints() {
        textView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalToSuperview().multipliedBy(0.5) // 화면 높이의 반절
        }

        pageLabel.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        pageNumberTextField.snp.makeConstraints {
            $0.top.equalTo(pageLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }
    }

    private func setupTextView() {
        textView.delegate = self
    }

    private func setupNavigationBar() {
        navigationItem.title = isEditMode ? "문장 수정" : String(localized: .quoteSaveTitle)

        // 취소 버튼
        let cancelButton = UIBarButtonItem(
            title: String(localized: .actionCancel),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .forestGreen
        navigationItem.leftBarButtonItem = cancelButton

        // 저장 버튼
        let saveButton = UIBarButtonItem(
            title: String(localized: .actionSave),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        saveButton.tintColor = .forestGreen
        navigationItem.rightBarButtonItem = saveButton

        // 네비게이션 바 스타일 설정
        setupNavigationBarAppearance()
        updateSaveButtonState()
    }

    private func setupNavigationBarAppearance() {
        // 바텀 시트에 적합한 네비게이션 바 스타일
        guard let navigationBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [
            .font: UIFont.custom(weight: .semiBold, size: 17),
            .foregroundColor: UIColor.label
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
    }

    private func setupKeyboardHandling() {
        // 키보드 숨기기 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // 키보드 알림
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupModalBehavior() {
        // 모달이 취소/저장 버튼으로만 dismiss되도록 설정
        isModalInPresentation = true

        // Navigation controller의 modal presentation도 설정
        navigationController?.isModalInPresentation = true
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        if !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showDiscardConfirmation()
        } else {
            eventRelay.accept(.cancelled)
        }
    }

    @objc private func saveTapped() {
        let quote = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty, let quoteRepository = quoteRepository else { return }

        let pageNumber = Int(pageNumberTextField.text ?? "")

        if isEditMode, let quoteId = editingQuoteId {
            // 수정 모드: 기존 문장 업데이트
            Analytics.logEvent("quote_updated", parameters: [
                "book_id": bookId,
                "has_page_number": pageNumber != nil
            ])

            updateExistingQuote(quoteId: quoteId, newQuote: quote, newPageNumber: pageNumber)
        } else {
            // 새로 저장
            Analytics.logEvent("quote_saved", parameters: [
                "book_id": bookId,
                "has_page_number": pageNumber != nil
            ])

            let realmQuote = RealmQuote(
                bookId: bookId,
                quote: quote,
                pageNumber: pageNumber
            )

            quoteRepository.saveQuote(realmQuote)
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] _ in
                        self?.eventRelay.accept(.quoteSaved(quote))
                    },
                    onError: { [weak self] error in
                        print("Failed to save quote: \(error.localizedDescription)")
                        self?.showSaveErrorAlert()
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    private func updateExistingQuote(quoteId: String, newQuote: String, newPageNumber: Int?) {
        do {
            let realm = try Realm()
            guard let objectId = try? ObjectId(string: quoteId),
                  let realmQuote = realm.object(ofType: RealmQuote.self, forPrimaryKey: objectId) else {
                print("Quote not found for update")
                return
            }

            try realm.write {
                realmQuote.quote = newQuote
                realmQuote.pageNumber = newPageNumber
            }

            eventRelay.accept(.quoteSaved(newQuote))
        } catch {
            print("Failed to update quote: \(error.localizedDescription)")
            showSaveErrorAlert()
        }
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
//        let keyboardHeight = keyboardFrame.height

        // 텍스트뷰 높이 조정
        textView.snp.remakeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalToSuperview().multipliedBy(0.4) // 키보드가 올라올 때 조금 작게
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        // 텍스트뷰 높이 복원
        textView.snp.remakeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalToSuperview().multipliedBy(0.5)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Helper Methods
    private func updateSaveButtonState() {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = hasText

        // 텍스트가 있으면 더욱 확실하게 modal dismiss 방지
        updateModalPresentationState()
    }

    private func updateModalPresentationState() {
        // 항상 modal presentation 유지
        isModalInPresentation = true
        navigationController?.isModalInPresentation = true
    }


    private func showDiscardConfirmation() {
        let alert = UIAlertController(
            title: String(localized: .quoteSaveDiscardTitle),
            message: String(localized: .quoteSaveDiscardMessage),
            preferredStyle: .alert
        )

        // 1. 계속 작성 (취소 스타일 - 기본 액션)
        alert.addAction(UIAlertAction(title: String(localized: .quoteSaveContinueEditing), style: .cancel))

        // 2. 삭제 (파괴적 스타일)
        alert.addAction(UIAlertAction(title: String(localized: .quoteSaveDiscard), style: .destructive) { [weak self] _ in
            self?.eventRelay.accept(.cancelled)
        })

        present(alert, animated: true)
    }

    private func showSaveErrorAlert() {
        let alert = UIAlertController(
            title: String(localized: .quoteSaveErrorTitle),
            message: String(localized: .quoteSaveErrorMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .actionConfirm), style: .default))

        present(alert, animated: true)
    }

    // MARK: - Edit Mode
    private func loadEditingQuoteId(quote: String) {
        guard let quoteRepository = quoteRepository else { return }

        quoteRepository.getQuotes(for: bookId)
            .take(1)
            .subscribe(onNext: { [weak self] quotes in
                // Realm Results를 Array로 변환하여 검색
                let quotesArray = Array(quotes)
                if let matchingQuote = quotesArray.first(where: { $0.quote == quote }) {
                    self?.editingQuoteId = String(describing: matchingQuote.id)
                }
            }, onError: { error in
                print("Failed to load quote ID for editing: \(error)")
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextViewDelegate
extension QuoteSaveViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSaveButtonState()
    }
}
