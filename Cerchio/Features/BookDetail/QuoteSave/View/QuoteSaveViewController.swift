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
    enum Event {
        case quoteSaved(String)
        case cancelled
    }

    private let eventRelay = PublishRelay<Event>()
    var events: Observable<Event> { eventRelay.asObservable() }

    private let bookId: String
    private var quoteRepository: QuoteRepositoryProtocol?
    private let disposeBag = DisposeBag()

    private var isEditMode: Bool = false
    private var editingQuoteId: String?

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

    init(bookId: String, existingQuote: String? = nil, existingPageNumber: Int? = nil) {
        self.bookId = bookId
        super.init(nibName: nil, bundle: nil)

        if let existingQuote = existingQuote {
            self.isEditMode = true
            self.preloadedQuote = existingQuote
            self.preloadedPageNumber = existingPageNumber
        }
    }

    private var preloadedQuote: String?
    private var preloadedPageNumber: Int?

    func setQuoteRepository(_ repository: QuoteRepositoryProtocol) {
        quoteRepository = repository
    }

    func configureForEdit(quoteId: String, quote: String, pageNumber: Int?) {
        isEditMode = true
        editingQuoteId = quoteId

        loadViewIfNeeded()
        textView.text = quote
        pageNumberTextField.text = pageNumber.map { String($0) }
        updateSaveButtonState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardHandling()
        setupModalBehavior()

        if let preloadedQuote = preloadedQuote {
            textView.text = preloadedQuote
            if let pageNumber = preloadedPageNumber {
                pageNumberTextField.text = String(pageNumber)
            }
            updateSaveButtonState()

            loadEditingQuoteId(quote: preloadedQuote)
        }

        textView.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isModalInPresentation = true
    }

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
            $0.height.equalToSuperview().multipliedBy(0.5)
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

        let cancelButton = UIBarButtonItem(
            title: String(localized: .actionCancel),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .forestGreen
        navigationItem.leftBarButtonItem = cancelButton

        let saveButton = UIBarButtonItem(
            title: String(localized: .actionSave),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        saveButton.tintColor = .forestGreen
        navigationItem.rightBarButtonItem = saveButton

        setupNavigationBarAppearance()
        updateSaveButtonState()
    }

    private func setupNavigationBarAppearance() {
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
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

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
        isModalInPresentation = true

        navigationController?.isModalInPresentation = true
    }

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
            Analytics.logEvent("quote_updated", parameters: [
                "book_id": bookId,
                "has_page_number": pageNumber != nil
            ])

            updateExistingQuote(quoteId: quoteId, newQuote: quote, newPageNumber: pageNumber)
        } else {
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

        textView.snp.remakeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalToSuperview().multipliedBy(0.4)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        textView.snp.remakeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.horizontalEdges.equalToSuperview().inset(16)
            $0.height.equalToSuperview().multipliedBy(0.5)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    private func updateSaveButtonState() {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        navigationItem.rightBarButtonItem?.isEnabled = hasText

        updateModalPresentationState()
    }

    private func updateModalPresentationState() {
        isModalInPresentation = true
        navigationController?.isModalInPresentation = true
    }

    private func showDiscardConfirmation() {
        let alert = UIAlertController(
            title: String(localized: .quoteSaveDiscardTitle),
            message: String(localized: .quoteSaveDiscardMessage),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(localized: .quoteSaveContinueEditing), style: .cancel))

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

    private func loadEditingQuoteId(quote: String) {
        guard let quoteRepository = quoteRepository else { return }

        quoteRepository.getQuotes(for: bookId)
            .take(1)
            .subscribe(onNext: { [weak self] quotes in
                let quotesArray = Array(quotes)
                if let matchingQuote = quotesArray.first(where: { $0.quote == quote }) {
                    self?.editingQuoteId = String(describing: matchingQuote.id)
                }
            }, onError: { error in
                print("Failed to load quote ID for editing: \(error)")
            })
            .disposed(by: disposeBag)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension QuoteSaveViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateSaveButtonState()
    }
}
