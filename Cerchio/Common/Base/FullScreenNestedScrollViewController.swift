//
//  FullScreenNestedScrollViewController.swift
//  Cerchio
//
//  Created by 송재훈 on 10/17/25.
//

import UIKit
import SnapKit

class FullScreenNestedScrollViewController: NestedScrollViewController {
    override var stickyThresholdOffset: CGFloat {
        return view.safeAreaInsets.top
    }

    private var navigationBarBackgroundView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        mainScrollView.contentInsetAdjustmentBehavior = .never
        setupNavigationBarBackgroundView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupTransparentNavigationBar()
        navigationController?.navigationBar.tintColor = .bookBackground
    }

    private func setupTransparentNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.shadowColor = nil
        appearance.shadowImage = UIImage()

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    private func setupNavigationBarBackgroundView() {
        navigationBarBackgroundView = UIView()
        navigationBarBackgroundView.backgroundColor = .forestGreen
        navigationBarBackgroundView.alpha = 0

        view.addSubview(navigationBarBackgroundView)

        navigationBarBackgroundView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
    }

    override func tabStickyStateDidChange(isSticky: Bool) {
        super.tabStickyStateDidChange(isSticky: isSticky)

        UIView.animate(withDuration: 0.3) {
            self.navigationBarBackgroundView.alpha = isSticky ? 1.0 : 0.0
        }
    }
}
