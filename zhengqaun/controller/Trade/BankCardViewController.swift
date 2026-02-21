//
//  BankCardViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

/// 银行卡数据模型
struct BankCard {
    let cardName: String
    let branchName: String
    let cardNumber: String
}

class BankCardViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 银行卡卡片
    private let cardContainer = UIView()
    private let cardNameLabel = UILabel()
    private let branchLabel = UILabel()
    private let cardNumberLabel = UILabel()
    private let modifyButton = UIButton(type: .system)
    
    // 绑定银行卡
    private let bindCardContainer = UIView()
    private let bindCardLabel = UILabel()
    private let bindCardIcon = UIImageView()
    
    // 数据
    private var bankCard: BankCard?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "我的银行卡"
        gk_navLineHidden = true
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupBankCard()
        setupBindCard()
    }
    
    // MARK: - 银行卡卡片
    private func setupBankCard() {
        // 卡片容器（金色背景）
        cardContainer.backgroundColor = UIColor(red: 0.95, green: 0.88, blue: 0.7, alpha: 1.0) // 金色/米色
        cardContainer.layer.cornerRadius = 12
        cardContainer.layer.shadowColor = UIColor.black.cgColor
        cardContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardContainer.layer.shadowRadius = 8
        cardContainer.layer.shadowOpacity = 0.1
        contentView.addSubview(cardContainer)
        cardContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 卡名/持卡人
        cardNameLabel.text = "测试"
        cardNameLabel.font = UIFont.systemFont(ofSize: 16)
        cardNameLabel.textColor = Constants.Color.textPrimary
        cardContainer.addSubview(cardNameLabel)
        cardNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 开户支行
        branchLabel.text = "开户支行:测试"
        branchLabel.font = UIFont.systemFont(ofSize: 14)
        branchLabel.textColor = Constants.Color.textSecondary
        cardContainer.addSubview(branchLabel)
        branchLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 卡号（大字体）
        cardNumberLabel.text = "6464646946464949"
        cardNumberLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        cardNumberLabel.textColor = UIColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0) // 深金色
        cardContainer.addSubview(cardNumberLabel)
        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 修改按钮
        modifyButton.setTitle("修改", for: .normal)
        modifyButton.setTitleColor(.white, for: .normal)
        modifyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        modifyButton.backgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        modifyButton.layer.cornerRadius = 6
        modifyButton.addTarget(self, action: #selector(modifyButtonTapped), for: .touchUpInside)
        cardContainer.addSubview(modifyButton)
        modifyButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            cardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardContainer.heightAnchor.constraint(equalToConstant: 140),
            
            cardNameLabel.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: 20),
            cardNameLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 20),
            
            branchLabel.topAnchor.constraint(equalTo: cardNameLabel.bottomAnchor, constant: 12),
            branchLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 20),
            
            modifyButton.centerYAnchor.constraint(equalTo: branchLabel.centerYAnchor),
            modifyButton.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -20),
            modifyButton.widthAnchor.constraint(equalToConstant: 60),
            modifyButton.heightAnchor.constraint(equalToConstant: 28),
            
            cardNumberLabel.topAnchor.constraint(equalTo: branchLabel.bottomAnchor, constant: 16),
            cardNumberLabel.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: 20),
            cardNumberLabel.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - 绑定银行卡
    private func setupBindCard() {
        bindCardContainer.backgroundColor = .white
        bindCardContainer.layer.cornerRadius = 8
        bindCardContainer.layer.borderWidth = 1
        bindCardContainer.layer.borderColor = Constants.Color.separator.cgColor
        bindCardContainer.isUserInteractionEnabled = true
        contentView.addSubview(bindCardContainer)
        bindCardContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(bindCardTapped))
        bindCardContainer.addGestureRecognizer(tapGesture)
        
        bindCardLabel.text = "绑定银行卡"
        bindCardLabel.font = UIFont.systemFont(ofSize: 15)
        bindCardLabel.textColor = Constants.Color.textPrimary
        bindCardContainer.addSubview(bindCardLabel)
        bindCardLabel.translatesAutoresizingMaskIntoConstraints = false
        
        bindCardIcon.image = UIImage(systemName: "pencil.circle.fill")
        bindCardIcon.tintColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        bindCardIcon.contentMode = .scaleAspectFit
        bindCardContainer.addSubview(bindCardIcon)
        bindCardIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bindCardContainer.topAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: 20),
            bindCardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bindCardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bindCardContainer.heightAnchor.constraint(equalToConstant: 50),
            bindCardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            bindCardLabel.leadingAnchor.constraint(equalTo: bindCardContainer.leadingAnchor, constant: 16),
            bindCardLabel.centerYAnchor.constraint(equalTo: bindCardContainer.centerYAnchor),
            
            bindCardIcon.trailingAnchor.constraint(equalTo: bindCardContainer.trailingAnchor, constant: -16),
            bindCardIcon.centerYAnchor.constraint(equalTo: bindCardContainer.centerYAnchor),
            bindCardIcon.widthAnchor.constraint(equalToConstant: 24),
            bindCardIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    // MARK: - Data
    private func loadData() {
        // 模拟数据
        bankCard = BankCard(
            cardName: "测试",
            branchName: "测试",
            cardNumber: "6464646946464949"
        )
        
        updateUI()
    }
    
    private func updateUI() {
        guard let card = bankCard else {
            // 如果没有银行卡，隐藏卡片，显示绑定提示
            cardContainer.isHidden = true
            return
        }
        
        cardContainer.isHidden = false
        cardNameLabel.text = card.cardName
        branchLabel.text = "开户支行:\(card.branchName)"
        cardNumberLabel.text = card.cardNumber
    }
    
    // MARK: - Actions
    @objc private func modifyButtonTapped() {
        let vc = BindBankCardViewController()
        // 传递当前银行卡信息用于回显
        vc.bankCard = bankCard
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func bindCardTapped() {
        let vc = BindBankCardViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}


