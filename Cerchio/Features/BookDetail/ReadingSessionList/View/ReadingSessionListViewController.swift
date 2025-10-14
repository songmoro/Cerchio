//
//  ReadingSessionListViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/6/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class ReadingSessionListViewController: BaseViewController<ReadingSessionListReactor> {

    // MARK: - UI Components

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.backgroundColor = UIColor(named: "Background")
        table.register(ReadingSessionCell.self, forCellReuseIdentifier: ReadingSessionCell.identifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        return table
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "아직 독서 기록이 없습니다"
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor(named: "ForestGreen")?.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Properties
    private var isEditMode: Bool = false
    var onAddRecordRequested: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        reactor?.action.onNext(.loadSessions)
    }

    // MARK: - Setup

    override func setupUI() {
        super.setupUI()

        view.backgroundColor = .systemBackground
        title = "독서 기록"

        setupNavigationBar()

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
        // + 버튼
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )

        // 편집 버튼
        let editButton = UIBarButtonItem(
            title: "편집",
            style: .plain,
            target: self,
            action: #selector(editButtonTapped)
        )

        navigationItem.rightBarButtonItems = [editButton, addButton]
    }

    // MARK: - Binding

    override func bind(reactor: ReadingSessionListReactor) {
        // State -> View
        reactor.state
            .map { $0.sessions }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: ReadingSessionCell.identifier, cellType: ReadingSessionCell.self)) { [weak self] index, session, cell in
                cell.configure(with: session)
                cell.onDeleteTapped = { [weak self] in
                    self?.showDeleteConfirmation(for: session.id)
                }
            }
            .disposed(by: disposeBag)

        reactor.state
            .map { $0.sessions.isEmpty && !$0.isLoading }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
            .drive(emptyLabel.rx.isHidden.mapObserver { !$0 })
            .disposed(by: disposeBag)

        // TableView 스와이프 삭제
        tableView.rx.itemDeleted
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self,
                      let reactor = self.reactor else { return }
                let session = reactor.currentState.sessions[indexPath.row]
                self.reactor?.action.onNext(.deleteSession(session.id))
            })
            .disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        onAddRecordRequested?()
    }

    func reloadSessions() {
        reactor?.action.onNext(.loadSessions)
    }

    @objc private func editButtonTapped() {
        isEditMode.toggle()
        tableView.setEditing(isEditMode, animated: true)

        // 버튼 텍스트 변경
        if let editButton = navigationItem.rightBarButtonItems?.first {
            editButton.title = isEditMode ? "완료" : "편집"
        }
    }

    // MARK: - Private Methods

    private func showDeleteConfirmation(for sessionId: String) {
        let alert = UIAlertController(
            title: "독서 기록 삭제",
            message: "이 독서 기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.reactor?.action.onNext(.deleteSession(sessionId))
        })

        present(alert, animated: true)
    }
}

// MARK: - Reading Session Cell

final class ReadingSessionCell: UITableViewCell {

    static let identifier = "ReadingSessionCell"

    // MARK: - UI Components

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(named: "ForestGreen")?.withAlphaComponent(0.7)
        return label
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(named: "ForestGreen")
        return label
    }()

    private let targetLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor(named: "ForestGreen")?.withAlphaComponent(0.6)
        return label
    }()

    private let deleteButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "trash")
        config.baseForegroundColor = UIColor.systemRed
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)

        let button = UIButton(configuration: config)
        return button
    }()

    // MARK: - Properties

    var onDeleteTapped: (() -> Void)?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor(named: "BookBackground")?.withAlphaComponent(0.1)
        selectionStyle = .none

        contentView.addSubview(dateLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(targetLabel)
        contentView.addSubview(deleteButton)

        dateLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(16)
        }

        durationLabel.snp.makeConstraints {
            $0.top.equalTo(dateLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().inset(16)
        }

        targetLabel.snp.makeConstraints {
            $0.top.equalTo(durationLabel.snp.bottom).offset(4)
            $0.leading.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(12)
        }

        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().inset(16)
            $0.size.equalTo(40)
        }

        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }

    // MARK: - Configuration

    func configure(with session: ReadingSession) {
        // Date formatting
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 M월 d일 a h:mm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateLabel.text = dateFormatter.string(from: session.createdAt)

        // Duration formatting (실제 읽은 시간 표시)
        let minutes = session.durationSeconds / 60
        let seconds = session.durationSeconds % 60

        if minutes > 0 {
            if seconds > 0 {
                durationLabel.text = String(format: "%d분 %d초", minutes, seconds)
            } else {
                durationLabel.text = String(format: "%d분", minutes)
            }
        } else {
            durationLabel.text = String(format: "%d초", seconds)
        }

        // Target formatting
        targetLabel.text = "목표: \(session.targetMinutes)분"
    }

    // MARK: - Actions

    @objc private func deleteButtonTapped() {
        onDeleteTapped?()
    }
}
