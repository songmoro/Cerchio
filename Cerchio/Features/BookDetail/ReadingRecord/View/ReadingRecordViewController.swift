//
//  ReadingRecordViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/3/25.
//

import UIKit
import ReactorKit
import RxSwift
import RxCocoa
import SnapKit

final class ReadingRecordViewController: BaseViewController<ReadingRecordReactor> {

    // MARK: - Lifecycle
    override func setupUI() {
        super.setupUI()
        view.backgroundColor = .systemBackground
        navigationItem.title = "독서 기록"
    }

    override func bind(reactor: ReadingRecordReactor) {
        // Action

        // State
    }
}
