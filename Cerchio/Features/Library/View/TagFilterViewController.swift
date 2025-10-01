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
    private var isFavoriteFilterEnabled: Bool = false
    var onFilterApplied: (([String], Bool) -> Void)?

    // MARK: - Constants
    private enum FilterOption {
        static let favorite = "favorite"
    }

    // MARK: - UI Components
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.register(TagFilterCell.self, forCellReuseIdentifier: TagFilterCell.identifier)
        table.backgroundColor = .systemBackground
        return table
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

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
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
    func configure(with tags: [String], selectedTags: [String], isFavoriteEnabled: Bool = false) {
        self.availableTags = tags
        self.selectedTags = Set(selectedTags)
        self.isFavoriteFilterEnabled = isFavoriteEnabled

        tableView.reloadData()
    }

    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func applyTapped() {
        onFilterApplied?(Array(selectedTags), isFavoriteFilterEnabled)
        dismiss(animated: true)
    }

    @objc private func clearTapped() {
        selectedTags.removeAll()
        isFavoriteFilterEnabled = false
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension TagFilterViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1 // Favorite filter
        } else {
            // 태그가 없으면 1개 행(빈 메시지), 있으면 태그 개수
            return availableTags.isEmpty ? 1 : availableTags.count
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "필터 옵션"
        } else {
            return "태그"
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            // 즐겨찾기 필터 셀
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TagFilterCell.identifier, for: indexPath) as? TagFilterCell else {
                return UITableViewCell()
            }
            cell.configure(with: "즐겨찾기", isSelected: isFavoriteFilterEnabled, isFavoriteOption: true)
            return cell
        } else {
            // 태그 섹션
            if availableTags.isEmpty {
                // 빈 태그 메시지 셀
                let cell = UITableViewCell()
                cell.textLabel?.text = "사용 가능한 태그가 없습니다"
                cell.textLabel?.textColor = .secondaryLabel
                cell.textLabel?.font = .systemFont(ofSize: 14)
                cell.textLabel?.textAlignment = .center
                cell.selectionStyle = .none
                return cell
            } else {
                // 태그 필터 셀
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TagFilterCell.identifier, for: indexPath) as? TagFilterCell else {
                    return UITableViewCell()
                }
                let tag = availableTags[indexPath.row]
                let isSelected = selectedTags.contains(tag)
                cell.configure(with: tag, isSelected: isSelected, isFavoriteOption: false)
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension TagFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            // Favorite filter toggle
            isFavoriteFilterEnabled.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
        } else {
            // 태그가 없으면 아무 동작 안 함
            guard !availableTags.isEmpty else { return }

            // Tag filter toggle
            let tag = availableTags[indexPath.row]

            if selectedTags.contains(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }

            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
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

    func configure(with tag: String, isSelected: Bool, isFavoriteOption: Bool = false) {
        if isFavoriteOption {
            tagLabel.text = tag
        } else {
            tagLabel.text = "#\(tag)"
        }
        checkmarkImageView.isHidden = !isSelected
    }
}
