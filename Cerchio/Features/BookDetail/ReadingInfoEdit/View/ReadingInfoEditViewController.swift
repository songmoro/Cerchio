//
//  ReadingInfoEditViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ReadingInfoEditViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private var currentTotalPages: Int = 0
    private var currentStartDate: Date?
    private var currentEndDate: Date?
    private var isStartDateCleared = false
    private var isEndDateCleared = false
    var onSaved: ((Int, Date?, Date?) -> Void)?

    private let pagesTextField: UITextField = {
        let field = UITextField()
        field.placeholder = String(localized: .`reading_info_edit.pages_placeholder`)
        field.borderStyle = .roundedRect
        field.keyboardType = .numberPad
        field.font = .custom(weight: .regular, size: 16)
        return field
    }()

    private let pagesLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .`reading_info_edit.total_pages`)
        label.font = UIFont.custom(weight: .semiBold, size: 16)
        label.textColor = .label
        return label
    }()

    private let startDateLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .`reading_info_edit.start_date_label`)
        label.font = UIFont.custom(weight: .semiBold, size: 16)
        label.textColor = .label
        return label
    }()

    private lazy var startDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        picker.tintColor = .forestGreen
        picker.addTarget(self, action: #selector(startDateChanged), for: .valueChanged)
        return picker
    }()

    private let clearStartDateButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: .`reading_info_edit.clear_start_date`)
        config.baseForegroundColor = .systemRed
        config.contentInsets = .zero

        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .custom(weight: .regular, size: 14)
                return outgoing
            }
            button.configuration = config
        }
        return button
    }()

    private let endDateLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: .`reading_info_edit.end_date_label`)
        label.font = UIFont.custom(weight: .semiBold, size: 16)
        label.textColor = .label
        return label
    }()

    private let readingStatusSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            String(localized: .`reading_info_edit.reading_status.reading`),
            String(localized: .`reading_info_edit.reading_status.completed`)
        ])
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = .forestGreen
        control.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        return control
    }()

    private lazy var endDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.maximumDate = Date()
        picker.tintColor = .forestGreen
        picker.addTarget(self, action: #selector(endDateChanged), for: .valueChanged)
        return picker
    }()

    private let clearEndDateButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = String(localized: .`reading_info_edit.clear_end_date`)
        config.baseForegroundColor = .systemRed
        config.contentInsets = .zero

        let button = UIButton(configuration: config)
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            config?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .custom(weight: .regular, size: 14)
                return outgoing
            }
            button.configuration = config
        }
        return button
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        return view
    }()

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
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        pagesTextField.snp.makeConstraints {
            $0.top.equalTo(pagesLabel.snp.bottom).offset(8)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        startDateLabel.snp.makeConstraints {
            $0.top.equalTo(pagesTextField.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        startDatePicker.snp.makeConstraints {
            $0.top.equalTo(startDateLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        clearStartDateButton.snp.makeConstraints {
            $0.top.equalTo(startDatePicker.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
        }

        endDateLabel.snp.makeConstraints {
            $0.top.equalTo(clearStartDateButton.snp.bottom).offset(32)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        readingStatusSegmentedControl.snp.makeConstraints {
            $0.top.equalTo(endDateLabel.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
            $0.height.equalTo(32)
        }

        endDatePicker.snp.makeConstraints {
            $0.top.equalTo(readingStatusSegmentedControl.snp.bottom).offset(12)
            $0.horizontalEdges.equalToSuperview().inset(20)
        }

        clearEndDateButton.snp.makeConstraints {
            $0.top.equalTo(endDatePicker.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(20)
        }
    }

    private func setupNavigationBar() {
        title = String(localized: .`reading_info_edit.title`)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.forestGreen]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .forestGreen

        let cancelButton = UIBarButtonItem(
            title: String(localized: .`action.cancel`),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        let saveButton = UIBarButtonItem(
            title: String(localized: .`circular_menu.common.save`),
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
        HapticFeedbackManager.shared.selection()
        let isCompleted = readingStatusSegmentedControl.selectedSegmentIndex == 1

        endDatePicker.isHidden = !isCompleted
        clearEndDateButton.isHidden = !isCompleted

        if isCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                let pickerFrame = self.endDatePicker.frame
                let targetY = pickerFrame.origin.y - 20
                self.scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: true)
            }
        }
    }

    @objc private func startDateChanged() {
        HapticFeedbackManager.shared.selection()
        isStartDateCleared = false
        endDatePicker.minimumDate = startDatePicker.date

        if endDatePicker.date < startDatePicker.date {
            endDatePicker.date = startDatePicker.date
        }
    }

    @objc private func endDateChanged() {
        HapticFeedbackManager.shared.selection()
        isEndDateCleared = false
    }

    func configure(totalPages: Int, startDate: Date?, endDate: Date?) {
        self.currentTotalPages = totalPages
        self.currentStartDate = startDate
        self.currentEndDate = endDate

        pagesTextField.text = "\(totalPages)"

        if let startDate = startDate {
            startDatePicker.date = startDate
            endDatePicker.minimumDate = startDate
        } else {
            startDatePicker.date = Date()
            endDatePicker.minimumDate = nil
        }

        if let endDate = endDate {
            endDatePicker.date = endDate
            readingStatusSegmentedControl.selectedSegmentIndex = 1
            endDatePicker.isHidden = false
            clearEndDateButton.isHidden = false
        } else {
            endDatePicker.date = Date()
            readingStatusSegmentedControl.selectedSegmentIndex = 0
            endDatePicker.isHidden = true
            clearEndDateButton.isHidden = true
        }
    }

    @objc private func cancelTapped() {
        HapticFeedbackManager.shared.impact()
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        HapticFeedbackManager.shared.impact()
        let pagesText = pagesTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let totalPages = Int(pagesText) ?? currentTotalPages

        let startDate = isStartDateCleared ? nil : startDatePicker.date

        let endDate: Date?
        if readingStatusSegmentedControl.selectedSegmentIndex == 0 {
            endDate = nil
        } else {
            endDate = isEndDateCleared ? nil : endDatePicker.date
        }

        if let start = startDate, let end = endDate {
            if end < start {
                showDateValidationAlert()
                return
            }
        }

        onSaved?(totalPages, startDate, endDate)
        dismiss(animated: true)
    }

    private func showDateValidationAlert() {
        let alert = UIAlertController(
            title: String(localized: .`reading_info_edit.date_error.title`),
            message: String(localized: .`reading_info_edit.date_error.message`),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .`action.confirm`), style: .default))
        present(alert, animated: true)
    }

    @objc private func clearStartDateTapped() {
        HapticFeedbackManager.shared.impact()
        isStartDateCleared = true
        startDatePicker.date = Date()
        endDatePicker.minimumDate = nil

        let alert = UIAlertController(
            title: String(localized: .`reading_info_edit.start_date_cleared.title`),
            message: String(localized: .`reading_info_edit.start_date_cleared.message`),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .`action.confirm`), style: .default))
        present(alert, animated: true)
    }

    @objc private func clearEndDateTapped() {
        HapticFeedbackManager.shared.impact()
        isEndDateCleared = true
        endDatePicker.date = Date()

        let alert = UIAlertController(
            title: String(localized: .`reading_info_edit.end_date_cleared.title`),
            message: String(localized: .`reading_info_edit.end_date_cleared.message`),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: String(localized: .`action.confirm`), style: .default))
        present(alert, animated: true)
    }
}
