//
//  TagEditViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/1/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class TagEditViewController: UIViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var currentTags: Set<String> = []
    private var allAvailableTags: [String] = []
    var onTagsSaved: (([String]) -> Void)?

    // MARK: - UI Components
    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "예: #판타지 #과학"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.font = .custom(weight: .regular, size: 16)
        return field
    }()

    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "#을 기준으로 태그를 입력하세요"
        label.font = .custom(weight: .regular, size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let suggestionsLabel: UILabel = {
        let label = UILabel()
        label.text = "기존 태그 목록"
        label.font = UIFont.custom(weight: .semiBold, size: 16)
        label.textColor = .label
        return label
    }()

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(TagSuggestionCell.self, forCellReuseIdentifier: TagSuggestionCell.identifier)
        table.backgroundColor = .systemGroupedBackground
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "사용 가능한 태그가 없습니다"
        label.textColor = .secondaryLabel
        label.font = .custom(weight: .regular, size: 14)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textField.becomeFirstResponder()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(textField)
        view.addSubview(instructionLabel)
        view.addSubview(suggestionsLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        textField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(44)
        }

        instructionLabel.snp.makeConstraints {
            $0.top.equalTo(textField.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        suggestionsLabel.snp.makeConstraints {
            $0.top.equalTo(instructionLabel.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        tableView.snp.makeConstraints {
            $0.top.equalTo(suggestionsLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalTo(tableView)
        }
    }

    private func setupNavigationBar() {
        title = "태그 편집"

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

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Public Methods
    func configure(currentTags: [String], allTags: [String]) {
        self.currentTags = Set(currentTags)
        self.allAvailableTags = Array(Set(allTags)).sorted()

        // 현재 태그를 텍스트 필드에 표시
        let tagText = currentTags.map { "#\($0)" }.joined(separator: " ")
        textField.text = tagText

        emptyLabel.isHidden = !allTags.isEmpty
        tableView.reloadData()
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        guard let inputText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !inputText.isEmpty else {
            onTagsSaved?([])
            dismiss(animated: true)
            return
        }

        let tags = parseTagsFromInput(inputText)
        onTagsSaved?(tags)
        dismiss(animated: true)
    }

    private func parseTagsFromInput(_ input: String) -> [String] {
        let components = input.components(separatedBy: "#")
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - UITableViewDataSource
extension TagEditViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAvailableTags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TagSuggestionCell.identifier, for: indexPath) as? TagSuggestionCell else {
            return UITableViewCell()
        }

        let tag = allAvailableTags[indexPath.row]
        let isSelected = currentTags.contains(tag)
        cell.configure(with: tag, isSelected: isSelected)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TagEditViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let tag = allAvailableTags[indexPath.row]

        if currentTags.contains(tag) {
            currentTags.remove(tag)
        } else {
            currentTags.insert(tag)
        }

        // 텍스트 필드 업데이트
        let tagText = Array(currentTags).sorted().map { "#\($0)" }.joined(separator: " ")
        textField.text = tagText

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - TagSuggestionCell
final class TagSuggestionCell: UITableViewCell {
    static let identifier = "TagSuggestionCell"

    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .regular, size: 16)
        label.textColor = .label
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .forestGreen
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(tagLabel)
        contentView.addSubview(checkmarkImageView)

        tagLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }

        checkmarkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
    }

    func configure(with tag: String, isSelected: Bool) {
        tagLabel.text = "#\(tag)"
        checkmarkImageView.isHidden = !isSelected
    }
}
