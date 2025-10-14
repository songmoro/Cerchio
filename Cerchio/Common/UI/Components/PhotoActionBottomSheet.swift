//
//  PhotoActionBottomSheet.swift
//  Cerchio
//
//  Created by 송재훈 on 10/14/25.
//

import UIKit
import SnapKit

final class PhotoActionBottomSheet: SnapshotBottomSheet {
    // MARK: - Properties
    enum Action {
        case view
        case download
        case delete
    }

    var onActionSelected: ((Action) -> Void)?

    private let actions: [(title: String, icon: String, action: Action, isDestructive: Bool)] = [
        ("보기", "eye", .view, false),
        ("다운로드", "square.and.arrow.down", .download, false),
        ("삭제", "trash", .delete, true)
    ]

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ActionCell.self, forCellReuseIdentifier: "ActionCell")
        return tableView
    }()

    // MARK: - Initialization
    override init(sourceView: UIView, sheetHeight: CGFloat) {
        super.init(sourceView: sourceView, sheetHeight: sheetHeight)
        setupTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupTableView() {
        containerView.addSubview(tableView)

        let padding: CGFloat = 12
        let snapshotHeight = cellSnapshot.bounds.height
        tableView.snp.makeConstraints {
            $0.horizontalEdges.bottom.equalToSuperview()
            $0.top.equalToSuperview().offset((snapshotHeight / 2) + padding)
        }
    }

    // MARK: - Actions
    private func handleAction(_ action: Action) {
        dismiss { [weak self] in
            self?.onActionSelected?(action)
        }
    }
}

// MARK: - UITableViewDataSource
extension PhotoActionBottomSheet: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell", for: indexPath) as? ActionCell else {
            return UITableViewCell()
        }

        let actionItem = actions[indexPath.row]
        cell.configure(
            title: actionItem.title,
            icon: actionItem.icon,
            isDestructive: actionItem.isDestructive
        )

        return cell
    }
}

// MARK: - UITableViewDelegate
extension PhotoActionBottomSheet: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let action = actions[indexPath.row].action
        handleAction(action)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

// MARK: - ActionCell
private final class ActionCell: UITableViewCell {
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .custom(weight: .medium, size: 16)
        label.textColor = .label
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .default

        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)

        iconImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconImageView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-20)
        }
    }

    func configure(title: String, icon: String, isDestructive: Bool) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: icon)

        let color: UIColor = isDestructive ? .systemRed : .label
        titleLabel.textColor = color
        iconImageView.tintColor = color
    }
}
