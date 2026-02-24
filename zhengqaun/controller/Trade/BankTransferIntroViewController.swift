//
//  BankTransferIntroViewController.swift
//  zhengqaun
//
//  银证转入简介说明页：展示证券监管相关说明文字，点击按钮后跳转银证账户页
//

import UIKit

class BankTransferIntroViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupScrollView()
        setupContent()
    }

    // MARK: - 导航栏
    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "银证转入"
        gk_navLineHidden = true
    }

    // MARK: - ScrollView
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: Constants.Navigation.contentTopBelowGKNavBar),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    // MARK: - 内容
    private func setupContent() {
        let pad: CGFloat = 24

        // 简介说明标题
        let titleLabel = UILabel()
        titleLabel.text = "简介说明"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = UIColor(red: 0.92, green: 0.35, blue: 0.14, alpha: 1.0) // 橙红色
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 说明正文
        let descLabel = UILabel()
        descLabel.text = "由于该账户受证券监管部门监督，根据证监部门2021反洗黑钱金融条例，为了避免出现不法分子黑钱投入机构单元账户，导致三方存管账户全面冻结带来的损失，因采取更高效审查机制支付通道，用户需通过三方存管和银行之间搭建的支付通道风控机制，进行出入金交易，三方存管账户进行一道关卡过滤黑钱！"
        descLabel.font = UIFont.systemFont(ofSize: 15)
        descLabel.textColor = UIColor(red: 0.92, green: 0.35, blue: 0.14, alpha: 1.0) // 橙红色
        descLabel.numberOfLines = 0
        descLabel.lineBreakMode = .byWordWrapping
        contentView.addSubview(descLabel)
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        // 进入银证账户按钮
        let enterButton = UIButton(type: .system)
        enterButton.setTitle("进入银证账户", for: .normal)
        enterButton.setTitleColor(.white, for: .normal)
        enterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        enterButton.backgroundColor = Constants.Color.themeBlue
        enterButton.layer.cornerRadius = 8
        enterButton.addTarget(self, action: #selector(enterBankAccount), for: .touchUpInside)
        contentView.addSubview(enterButton)
        enterButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            descLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            enterButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 40),
            enterButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            enterButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            enterButton.heightAnchor.constraint(equalToConstant: 48),
            enterButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - 跳转银证账户
    @objc private func enterBankAccount() {
        let vc = BankTransferInViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
