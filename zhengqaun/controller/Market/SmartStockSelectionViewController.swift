//
//  SmartStockSelectionViewController.swift
//  zhengqaun
//
//  智能选股：一张大长图 zhinengxuangu，可滑动展示
//

import UIKit

class SmartStockSelectionViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private var imageHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        gk_navTitle = "智能选股"
        gk_navTitleColor = .white
        view.backgroundColor = .black
        gk_navBackgroundColor = .clear

        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
        view.addSubview(scrollView)

        imageView.image = UIImage(named: "zhinengxuangu")
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)

        let heightC = imageView.heightAnchor.constraint(equalToConstant: 1)
        imageHeightConstraint = heightC

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            heightC
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let img = imageView.image else { return }
        let w = scrollView.bounds.width
        guard w > 0 else { return }
        let scale = w / img.size.width
        let h = img.size.height * scale
        if abs((imageHeightConstraint?.constant ?? 0) - h) > 1 {
            imageHeightConstraint?.constant = h
        }
    }
}
