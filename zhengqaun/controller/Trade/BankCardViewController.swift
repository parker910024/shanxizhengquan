//
//  BankCardViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//
import SVProgressHUD
import UIKit

/// 银行卡数据模型
struct BankCard: Codable {
    let id: Int
    let name: String
    let account: String
    let depositBank: String
    let khzhihang: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, khzhihang, account
        case depositBank = "deposit_bank"
    }
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

    // 无卡空态
    private let emptyStateView = UIView()
    private let addCardButton = UIButton(type: .system)
    private let tip1Label = UILabel()
    private let tip2Label = UILabel()

    // 数据
    private var bankCard: BankCard?

    // 空态/有卡时 contentView 底部约束切换
    private var emptyStateBottomConstraint: NSLayoutConstraint?
    private var bindCardBottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadData()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "我的银行卡"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
   
        gk_backStyle = .black
    }

    @objc private func searchTapped() {}
    
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

        setupEmptyState()
        setupBankCard()
        setupBindCard()
    }

    // MARK: - 无卡空态：橙红「添加储蓄卡」按钮 + 两条灰色说明
    private func setupEmptyState() {
        emptyStateView.backgroundColor = .white
        contentView.addSubview(emptyStateView)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false

        addCardButton.setTitle("添加储蓄卡", for: .normal)
        addCardButton.setTitleColor(.white, for: .normal)
        addCardButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        addCardButton.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
        addCardButton.layer.cornerRadius = 8
        addCardButton.addTarget(self, action: #selector(addCardTapped), for: .touchUpInside)
        emptyStateView.addSubview(addCardButton)
        addCardButton.translatesAutoresizingMaskIntoConstraints = false

        tip1Label.text = "1. 新用户注册后必须通过添加银行卡。"
        tip1Label.font = UIFont.systemFont(ofSize: 14)
        tip1Label.textColor = Constants.Color.textTertiary
        tip1Label.numberOfLines = 0
        emptyStateView.addSubview(tip1Label)
        tip1Label.translatesAutoresizingMaskIntoConstraints = false

        tip2Label.text = "2. 真实姓名必须和绑定银行卡户名一样。"
        tip2Label.font = UIFont.systemFont(ofSize: 14)
        tip2Label.textColor = Constants.Color.textTertiary
        tip2Label.numberOfLines = 0
        emptyStateView.addSubview(tip2Label)
        tip2Label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emptyStateView.topAnchor.constraint(equalTo: contentView.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            addCardButton.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 54),
            addCardButton.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            addCardButton.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            addCardButton.heightAnchor.constraint(equalToConstant: 48),
            tip1Label.topAnchor.constraint(equalTo: addCardButton.bottomAnchor, constant: 24),
            tip1Label.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            tip1Label.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            tip2Label.topAnchor.constraint(equalTo: tip1Label.bottomAnchor, constant: 8),
            tip2Label.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 16),
            tip2Label.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -16),
            tip2Label.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor, constant: -24)
        ])
        let bottomC = emptyStateView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        emptyStateBottomConstraint = bottomC
        bottomC.isActive = false
    }

    @objc private func addCardTapped() {
        let vc = BindBankCardViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
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
        
        let bindBottom = bindCardContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        bindCardBottomConstraint = bindBottom
        NSLayoutConstraint.activate([
            bindCardContainer.topAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: 20),
            bindCardContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bindCardContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bindCardContainer.heightAnchor.constraint(equalToConstant: 50),
            bindBottom,

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
        // 无卡时显示空态；有卡时从接口或缓存读取后赋值 bankCard
        Task {
            do {
                SVProgressHUD.show()
                let result = try await SecureNetworkManager.shared.request(api: Api.accountLst_api, method: .post, params: [:])
                debugPrint("raw =", result.raw) // 原始响应
                debugPrint("decrypted =", result.decrypted ?? "无法解密") // 解密后的明文（如果能解）
                await SVProgressHUD.dismiss()
                if let dict = result.decrypted, let data = dict["data"] as? [String: Any], let list = data["list"] as? [String: Any], let cards = list["data"] {
                    if dict["msg"] as? String != "success" {
                        DispatchQueue.main.async {
                            Toast.showInfo(dict["msg"] as? String ?? "")
                        }
                        return
                    } else {
                        let jsonData = try JSONSerialization.data(withJSONObject: cards, options: [])
                        let model = try JSONDecoder().decode([BankCard].self, from: jsonData)
                        debugPrint(model)
                        self.bankCard = model.first
                        
                        updateUI()
                    }
                }
            } catch {
                await SVProgressHUD.dismiss()
                debugPrint("error =", error.localizedDescription, #function)
                Toast.showError(error.localizedDescription)
            }
        }
        
    }
    
    private func updateUI() {
        if bankCard == nil {
            emptyStateView.isHidden = false
            cardContainer.isHidden = true
            bindCardContainer.isHidden = true
            bindCardBottomConstraint?.isActive = false
            emptyStateBottomConstraint?.isActive = true
        } else {
            emptyStateView.isHidden = true
            cardContainer.isHidden = false
            bindCardContainer.isHidden = false
            emptyStateBottomConstraint?.isActive = false
            bindCardBottomConstraint?.isActive = true
            let card = bankCard!
            cardNameLabel.text = card.name
            branchLabel.text = "开户支行:\(card.khzhihang)"
            cardNumberLabel.text = card.account
        }
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


