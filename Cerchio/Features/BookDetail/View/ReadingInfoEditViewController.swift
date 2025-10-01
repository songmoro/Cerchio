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
    private var currentEndDate: Date?
    var onSaved: ((Int, Date?, Date?) -> Void)?

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

    private let startDateLabel: UILabel = {
        let label = UILabel()
        label.text = "읽기 시작한 날짜"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        return picker
    }()

    private let clearStartDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("시작 날짜 초기화", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    private let endDateLabel: UILabel = {
        let label = UILabel()
        label.text = "읽기 완료한 날짜"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()

    private let readingStatusSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["읽는 중", "완료"])
        control.selectedSegmentIndex = 0
        return control
    }()

    private let endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        return picker
    }()

    private let clearEndDateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("완료 날짜 초기화", for: .normal)
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
        contentView.addSubview(startDateLabel)
        contentView.addSubview(startDatePicker)
        contentView.addSubview(clearStartDateButton)
        contentView.addSubview(endDateLabel)
        contentView.addSubview(readingStatusSegmentedControl)
        contentView.addSubview(endDatePicker)
        contentView.addSubview(clearEndDateButton)

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

        startDateLabel.snp.makeConstraints {
            $0.top.equalTo(pagesTextField.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        startDatePicker.snp.makeConstraints {
            $0.top.equalTo(startDateLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        clearStartDateButton.snp.makeConstraints {
            $0.top.equalTo(startDatePicker.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        endDateLabel.snp.makeConstraints {
            $0.top.equalTo(clearStartDateButton.snp.bottom).offset(32)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        readingStatusSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(endDateLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(32)
        }

        endDatePicker.snp.makeConstraints {
            $0.top.equalTo(readingStatusSegmentedControl.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        clearEndDateButton.snp.makeConstraints {
            $0.top.equalTo(endDatePicker.snp.bottom).offset(16)
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
        clearStartDateButton.addTarget(self, action: #selector(clearStartDateTapped), for: .touchUpInside)
        clearEndDateButton.addTarget(self, action: #selector(clearEndDateTapped), for: .touchUpInside)
        readingStatusSegmentedControl.addTarget(self, action: #selector(readingStatusChanged), for: .valueChanged)
    }

    @objc private func readingStatusChanged() {
        let isCompleted = readingStatusSegmentedControl.selectedSegmentIndex == 1

        // "읽는 중" 선택 시 날짜 선택 UI 숨기기, "완료" 선택 시 보이기
        endDatePicker.isHidden = !isCompleted
        clearEndDateButton.isHidden = !isCompleted
    }

    // MARK: - Public Methods
    func configure(totalPages: Int, startDate: Date?, endDate: Date?) {
        self.currentTotalPages = totalPages
        self.currentStartDate = startDate
        self.currentEndDate = endDate

        pagesTextField.text = "\(totalPages)"

        if let startDate = startDate {
            startDatePicker.date = startDate
        } else {
            startDatePicker.date = Date()
        }

        if let endDate = endDate {
            endDatePicker.date = endDate
            readingStatusSegmentedControl.selectedSegmentIndex = 1 // 완료
            endDatePicker.isHidden = false
            clearEndDateButton.isHidden = false
        } else {
            endDatePicker.date = Date()
            readingStatusSegmentedControl.selectedSegmentIndex = 0 // 읽는 중
            endDatePicker.isHidden = true
            clearEndDateButton.isHidden = true
        }
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        let pagesText = pagesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let totalPages = Int(pagesText) ?? currentTotalPages

        // 시작 날짜
        let startDate = currentStartDate != nil ? startDatePicker.date : nil

        // 완료 날짜: "읽는 중"이면 nil, "완료"면 선택된 날짜
        let endDate: Date?
        if readingStatusSegmentedControl.selectedSegmentIndex == 0 {
            // "읽는 중" 선택됨
            endDate = nil
        } else {
            // "완료" 선택됨
            endDate = currentEndDate != nil ? endDatePicker.date : endDatePicker.date
        }

        onSaved?(totalPages, startDate, endDate)
        dismiss(animated: true)
    }

    @objc private func clearStartDateTapped() {
        currentStartDate = nil
        startDatePicker.date = Date()

        let alert = UIAlertController(
            title: "시작 날짜 초기화",
            message: "읽기 시작 날짜가 초기화됩니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    @objc private func clearEndDateTapped() {
        currentEndDate = nil
        endDatePicker.date = Date()

        let alert = UIAlertController(
            title: "완료 날짜 초기화",
            message: "읽기 완료 날짜가 초기화됩니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
