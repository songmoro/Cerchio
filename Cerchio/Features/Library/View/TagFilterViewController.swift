//
//  TagFilterViewController.swift
//  Cerchio
//
//  Created by Claude Code on 10/1/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class TagFilterViewController: UIViewController {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var availableTags: [String] = []
    private var selectedTags: Set<String> = []
    var onFilterApplied: (([String]) -> Void)?

    // MARK: - UI Components
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(TagFilterCell.self, forCellReuseIdentifier: TagFilterCell.identifier)
        table.backgroundColor = .systemBackground
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "사용 가능한 태그가 없습니다"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
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

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupNavigationBar() {
        title = "태그 필터"

        let cancelButton = UIBarButtonItem(
            title: "취소",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )

        let applyButton = UIBarButtonItem(
            title: "적용",
            style: .done,
            target: self,
            action: #selector(applyTapped)
        )

        let clearButton = UIBarButtonItem(
            title: "초기화",
            style: .plain,
            target: self,
            action: #selector(clearTapped)
        )

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItems = [applyButton, clearButton]
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: - Public Methods
    func configure(with tags: [String], selectedTags: [String]) {
        self.availableTags = tags
        self.selectedTags = Set(selectedTags)

        emptyLabel.isHidden = !tags.isEmpty
        tableView.reloadData()
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func applyTapped() {
        onFilterApplied?(Array(selectedTags))
        dismiss(animated: true)
    }

    @objc private func clearTapped() {
        selectedTags.removeAll()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension TagFilterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableTags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TagFilterCell.identifier, for: indexPath) as? TagFilterCell else {
            return UITableViewCell()
        }

        let tag = availableTags[indexPath.row]
        let isSelected = selectedTags.contains(tag)
        cell.configure(with: tag, isSelected: isSelected)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TagFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let tag = availableTags[indexPath.row]

        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - TagFilterCell
final class TagFilterCell: UITableViewCell {
    static let identifier = "TagFilterCell"

    private let tagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
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
