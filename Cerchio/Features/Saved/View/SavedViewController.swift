//
//  SavedViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/25/25.
//

import UIKit
import SnapKit

class SavedViewController: UIViewController {
    private let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemPink
        title = "Saved"

        view.addSubview(titleLabel)
        titleLabel.text = "Saved Items"
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .systemBlue

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}