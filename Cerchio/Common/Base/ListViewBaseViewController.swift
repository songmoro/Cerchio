//
//  ListViewBaseViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/18/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

/// Base class for list view controllers with common navigation bar style
/// Provides:
/// - Right bar buttons: [+, 편집] (Add, Edit)
/// - Consistent navigation styling
/// - Abstract methods for child classes to implement
class ListViewBaseViewController<R: Reactor>: BaseViewController<R> {

    // MARK: - UI Components
    private var addButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!

    // MARK: - Properties
    open var isEditMode: Bool = false {
        didSet {
            editModeDidChange(isEditMode)
        }
    }

    // MARK: - Abstract Properties (Override in subclasses)

    /// Title for the view controller (override in subclass)
    open var viewTitle: String {
        return ""
    }

    /// Whether to show the add button (override to customize)
    open var showsAddButton: Bool {
        return true
    }

    /// Whether to show the edit button (override to customize)
    open var showsEditButton: Bool {
        return true
    }

    // MARK: - Lifecycle

    open override func setupUI() {
        super.setupUI()
        setupNavigationBar()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        title = viewTitle

        var rightBarButtonItems: [UIBarButtonItem] = []

        // 편집 버튼
        if showsEditButton {
            editButton = UIBarButtonItem(
                title: String(localized: .actionEdit),
                style: .plain,
                target: nil,
                action: nil
            )

            editButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.toggleEditMode()
                })
                .disposed(by: disposeBag)

            rightBarButtonItems.append(editButton)
        }

        // 추가 버튼
        if showsAddButton {
            addButton = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: nil,
                action: nil
            )

            addButton.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.addButtonTapped()
                })
                .disposed(by: disposeBag)

            rightBarButtonItems.append(addButton)
        }

        if !rightBarButtonItems.isEmpty {
            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }

    private func toggleEditMode() {
        isEditMode.toggle()
        updateEditButton()
    }

    private func updateEditButton() {
        guard let editButton = editButton else { return }

        if isEditMode {
            editButton.title = String(localized: .actionDone)
            editButton.style = .done
        } else {
            editButton.title = String(localized: .actionEdit)
            editButton.style = .plain
        }
    }

    // MARK: - Abstract Methods (Override in subclasses)

    /// Called when add button is tapped
    open func addButtonTapped() {
    }

    /// Called when edit mode changes
    open func editModeDidChange(_ isEditMode: Bool) {
    }
}
