//
//  ReadingInfoEditViewController.swift
//  Cerchio
//
//  Created by Claude Code on 10/1/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ReadingInfoEditViewController: UIViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var currentTotalPages: Int = 0
    private var currentStartDate: Date?
    var onSaved: ((Int, Date?) -> Void)?

    // MARK: - UI Components
    private let pagesTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "페이지 수 입력"
        field.borderStyle = .roundedRect
        field.keyboardType = .numberPad
        field.font = .systemFont(ofSize: 16)
        return field
    }()

    private let pagesLabel: UILabel = {
        let label = UILabel()
        label.text = "총 페이지"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "읽기 시작한 날짜"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        return picker
    }()

    private let clearDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("날짜 초기화", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pagesTextField.becomeFirstResponder()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(pagesLabel)
        contentView.addSubview(pagesTextField)
        contentView.addSubview(dateLabel)
        contentView.addSubview(datePicker)
        contentView.addSubview(clearDateButton)

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        pagesLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        pagesTextField.snp.makeConstraints {
            $0.top.equalTo(pagesLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        dateLabel.snp.makeConstraints {
            $0.top.equalTo(pagesTextField.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        datePicker.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        clearDateButton.snp.makeConstraints {
            $0.top.equalTo(datePicker.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    private func setupNavigationBar() {
        title = "독서 정보 편집"

        let cancelButton = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        let saveButton = UIBarButtonItem(
            title: "저장",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupActions() {
        clearDateButton.addTarget(self, action: #selector(clearDateTapped), for: .touchUpInside)
    }

    // MARK: - Public Methods
    func configure(totalPages: Int, startDate: Date?) {
        self.currentTotalPages = totalPages
        self.currentStartDate = startDate

        pagesTextField.text = "\(totalPages)"

        if let startDate = startDate {
            datePicker.date = startDate
        } else {
            datePicker.date = Date()
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let pagesText = pagesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let totalPages = Int(pagesText) ?? currentTotalPages

        // 날짜가 초기화되었는지 확인
        let startDate = currentStartDate != nil ? datePicker.date : nil

        onSaved?(totalPages, startDate)
        dismiss(animated: true)
    }

    @objc private func clearDateTapped() {
        currentStartDate = nil
        datePicker.date = Date()

        let alert = UIAlertController(
            title: "날짜 초기화",
            message: "읽기 시작 날짜가 초기화됩니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
