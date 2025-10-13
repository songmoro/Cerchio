//
//  QuoteActionBottomSheet.swift
//  Cerchio
//
//  Created by 송재훈 on 10/13/25.
//

import UIKit
import SnapKit

final class QuoteActionBottomSheet: UIView {
    // MARK: - Properties
    enum Action {
        case share
        case edit
        case delete
    }

    var onActionSelected: ((Action) -> Void)?
    var onDismiss: (() -> Void)?

    private let cellSnapshot: UIView
    private let sheetHeight: CGFloat
    private var initialContainerOffset: CGFloat = 0

    private let actions: [(title: String, icon: String, action: Action, isDestructive: Bool)] = [
        (String(localized: .`action.share`), "square.and.arrow.up", .share, false),
        (String(localized: .actionEdit), "pencil", .edit, false),
        (String(localized: .actionDelete), "trash", .delete, true)
    ]

    // MARK: - UI Components
    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.alpha = 0
        return view
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let snapshotContainer = UIView()

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
    init(cellSnapshot: UIView, in parentView: UIView) {
        self.cellSnapshot = cellSnapshot
        self.cellSnapshot.layer.cornerRadius = 12
        self.cellSnapshot.layer.borderWidth = 1
        self.cellSnapshot.layer.borderColor = UIColor.forestGreen.cgColor
        self.sheetHeight = parentView.bounds.height / 3
        super.init(frame: parentView.bounds)

        setupUI()
        setupGestures()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        addSubview(dimmingView)
        addSubview(containerView)
        addSubview(snapshotContainer)

        snapshotContainer.addSubview(cellSnapshot)
        containerView.addSubview(tableView)

        setupConstraints()
        setupGestures()
    }

    private func setupConstraints() {
        dimmingView.snp.makeConstraints {
            $0.edges.equalTo(self)
        }

        containerView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(sheetHeight)
        }
        
        snapshotContainer.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(containerView.snp.top).offset(cellSnapshot.bounds.height / 2)
            $0.size.equalTo(cellSnapshot.bounds.size)
        }

        cellSnapshot.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        let padding: CGFloat = 12
        tableView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.top.equalTo(containerView.snp.top).offset((cellSnapshot.bounds.height / 2) + padding)
        }
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmingTap))
        dimmingView.addGestureRecognizer(tapGesture)

        let containerPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        containerView.addGestureRecognizer(containerPanGesture)

        let snapshotPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        snapshotContainer.addGestureRecognizer(snapshotPanGesture)
    }

    // MARK: - Actions
    private func handleAction(_ action: Action) {
        dismiss {
            self.onActionSelected?(action)
        }
    }

    @objc private func handleDimmingTap() {
        dismiss {
            self.onDismiss?()
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)

        switch gesture.state {
        case .began:
            initialContainerOffset = containerView.transform.ty

        case .changed:
            let newOffset = max(0, initialContainerOffset + translation.y)
            containerView.transform = CGAffineTransform(translationX: 0, y: newOffset)
            snapshotContainer.transform = CGAffineTransform(translationX: 0, y: newOffset)

            let progress = min(1, newOffset / sheetHeight)
            dimmingView.alpha = 1 - progress

        case .ended, .cancelled:
            let shouldDismiss = translation.y > sheetHeight / 3 || velocity.y > 1000

            if shouldDismiss {
                dismiss {
                    self.onDismiss?()
                }
            } else {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: .curveEaseOut
                ) {
                    self.containerView.transform = .identity
                    self.snapshotContainer.transform = .identity
                    self.dimmingView.alpha = 1
                }
            }

        default:
            break
        }
    }

    // MARK: - Presentation
    func show(in parentView: UIView) {
        parentView.addSubview(self)

        // Initial position (off-screen)
        containerView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
        snapshotContainer.transform = CGAffineTransform(translationX: 0, y: sheetHeight)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.dimmingView.alpha = 1
                self.containerView.transform = .identity
                self.snapshotContainer.transform = .identity
            }
        )
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.dimmingView.alpha = 0
                self.containerView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
                self.snapshotContainer.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)

            },
            completion: { _ in
                self.removeFromSuperview()
                completion?()
            }
        )
    }
}

// MARK: - UITableViewDataSource
extension QuoteActionBottomSheet: UITableViewDataSource {
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
extension QuoteActionBottomSheet: UITableViewDelegate {
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
            $0.width.height.equalTo(24)
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
