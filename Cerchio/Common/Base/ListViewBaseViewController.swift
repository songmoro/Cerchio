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

class ListViewBaseViewController<R: Reactor>: BaseViewController<R> {

    private var addButton: UIBarButtonItem!
    private var editButton: UIBarButtonItem!

    open var isEditMode: Bool = false {
        didSet {
            editModeDidChange(isEditMode)
        }
    }

    open var viewTitle: String {
        return ""
    }

    open var showsAddButton: Bool {
        return true
    }

    open var showsEditButton: Bool {
        return true
    }

    open override func setupUI() {
        super.setupUI()
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        title = viewTitle

        var rightBarButtonItems: [UIBarButtonItem] = []

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

    open func addButtonTapped() {
    }

    open func editModeDidChange(_ isEditMode: Bool) {
    }
}
