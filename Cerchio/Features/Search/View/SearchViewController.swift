//
//  SearchViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 9/25/25.
//

import UIKit
import SnapKit

class SearchViewController: UIViewController {
    private let searchBar = UISearchBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemPink
        title = "Search"

        view.addSubview(searchBar)
        searchBar.placeholder = "Search..."
        searchBar.backgroundColor = .systemGray6
        searchBar.layer.cornerRadius = 12

        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
    }
}