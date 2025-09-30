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

protocol QuoteSaveViewControllerDelegate: AnyObject {
    func quoteSaveViewController(_ controller: QuoteSaveViewController, didSaveQuote quote: String)
    func quoteSaveViewControllerDidCancel(_ controller: QuoteSaveViewController)
}

final class QuoteSaveViewController: UIViewController {
    weak var delegate: QuoteSaveViewControllerDelegate?

    // MARK: - Properties
    private let bookId: String
    private var quoteRepository: QuoteRepositoryProtocol?
    private let disposeBag = DisposeBag()

    // MARK: - UI Components
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 16, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .systemBackground
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = true
        return textView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("quote_save.placeholder", comment: "Quote placeholder text")
        label.textColor = .placeholderText
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    private let pageNumberTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("quote_save.page_placeholder", comment: "Page number placeholder")
        textField.borderStyle = .roundedRect
        textField.keyboardType = .numberPad
        textField.clearButtonMode = .whileEditing
        return textField
    }()

    private let pageLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("quote_save.page_label", comment: "Page label")
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()

    // MARK: - Initialization
    init(bookId: String) {
        self.bookId = bookId
        super.init(nibName: nil, bundle: nil)
    }

    func setQuoteRepository(_ repository: QuoteRepositoryProtocol) {
        quoteRepository = repository
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
        view.addSubview(placeholderLabel)
        view.addSubview(pageLabel)
        view.addSubview(pageNumberTextField)

        setupConstraints()
        setupTextView()
    }

    private func setupConstraints() {
        textView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalToSuperview().multipliedBy(0.5) // 화면 높이의 반절
        }

        placeholderLabel.snp.makeConstraints {
            $0.top.equalTo(textView).offset(16)
            $0.leading.equalTo(textView).offset(16)
            $0.trailing.equalTo(textView).inset(16)
        }

        pageLabel.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(24)
            $0.leading.equalToSuperview().offset(16)
        }

        pageNumberTextField.snp.makeConstraints {
            $0.top.equalTo(pageLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(44)
        }
    }

    private func setupTextView() {
        textView.delegate = self
        updatePlaceholderVisibility()
    }

    private func setupNavigationBar() {
        navigationItem.title = NSLocalizedString("quote_save.title", comment: "Quote save screen title")

        // 취소 버튼
        let cancelButton = UIBarButtonItem(
            title: NSLocalizedString("action.cancel", comment: "Cancel button"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        cancelButton.tintColor = .systemBlue
        navigationItem.leftBarButtonItem = cancelButton

        // 저장 버튼
        let saveButton = UIBarButtonItem(
            title: NSLocalizedString("action.save", comment: "Save button"),
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        saveButton.tintColor = .systemBlue
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
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
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
            delegate?.quoteSaveViewControllerDidCancel(self)
        }
    }

    @objc private func saveTapped() {
        let quote = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty, let quoteRepository = quoteRepository else { return }

        let pageNumber = Int(pageNumberTextField.text ?? "")

        // Repository를 통해 저장
        let realmQuote = RealmQuote(
            bookId: bookId,
            quote: quote,
            pageNumber: pageNumber
        )

        quoteRepository.saveQuote(realmQuote)
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] _ in
                    self?.delegate?.quoteSaveViewController(self!, didSaveQuote: quote)
                },
                onError: { [weak self] error in
                    print("❌ Failed to save quote: \\(error.localizedDescription)")
                    self?.showSaveErrorAlert()
                }
            )
            .disposed(by: disposeBag)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height

        // 텍스트뷰 높이 조정
        textView.snp.updateConstraints {
            $0.height.equalToSuperview().multipliedBy(0.4) // 키보드가 올라올 때 조금 작게
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        // 텍스트뷰 높이 복원
        textView.snp.updateConstraints {
            $0.height.equalToSuperview().multipliedBy(0.5)
        }

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Helper Methods
    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

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
            title: NSLocalizedString("quote_save.discard_title", comment: "Discard confirmation title"),
            message: NSLocalizedString("quote_save.discard_message", comment: "Discard confirmation message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("quote_save.discard", comment: "Discard action"), style: .destructive) { _ in
            self.delegate?.quoteSaveViewControllerDidCancel(self)
        })

        alert.addAction(UIAlertAction(title: NSLocalizedString("action.cancel", comment: "Cancel action"), style: .cancel))

        present(alert, animated: true)
    }

    private func showSaveErrorAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("quote_save.error_title", comment: "Save error title"),
            message: NSLocalizedString("quote_save.error_message", comment: "Save error message"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: NSLocalizedString("action.confirm", comment: "Confirm action"), style: .default))

        present(alert, animated: true)
    }

    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextViewDelegate
extension QuoteSaveViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateSaveButtonState()
    }
}