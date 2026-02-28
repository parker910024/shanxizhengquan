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
    
    /// 脱敏卡号：前4后4，中间*
    var displayCardNumber: String {
        if account.count <= 8 { return account }
        return account.prefix(4) + " **** **** " + account.suffix(4)
    }
    
    /// 银行名称
    var displayBankName: String {
        return depositBank.isEmpty ? "银行卡" : depositBank
    }
}

class BankCardViewController: ZQViewController {
    
    // 资金行
    private let fundsRow = UIView()
    private let t1Label = UILabel()
    private let t1AmountLabel = UILabel()
    private let transferLabel = UILabel()
    private let transferAmountLabel = UILabel()
    
    // 卡片列表容器
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    // 底部
    private let addCardButton = UIButton(type: .system)
    private let tip1Label = UILabel()
    private let tip2Label = UILabel()

    // 数据
    private var bankCards: [BankCard] = []
    private var maxCards: Int = Int.max
    
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
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1.0) // #F8F8FA
        
        // 资金行（对齐安卓 layout_funds_row）
        fundsRow.backgroundColor = .white
        view.addSubview(fundsRow)
        fundsRow.translatesAutoresizingMaskIntoConstraints = false
        
        t1Label.text = "T+1资金"
        t1Label.font = UIFont.systemFont(ofSize: 14)
        t1Label.textColor = Constants.Color.textPrimary
        fundsRow.addSubview(t1Label)
        t1Label.translatesAutoresizingMaskIntoConstraints = false
        
        t1AmountLabel.text = "0.00"
        t1AmountLabel.font = UIFont.systemFont(ofSize: 14)
        t1AmountLabel.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        fundsRow.addSubview(t1AmountLabel)
        t1AmountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        transferLabel.text = "可转出金额"
        transferLabel.font = UIFont.systemFont(ofSize: 14)
        transferLabel.textColor = Constants.Color.textPrimary
        transferLabel.textAlignment = .right
        fundsRow.addSubview(transferLabel)
        transferLabel.translatesAutoresizingMaskIntoConstraints = false
        
        transferAmountLabel.text = "0.00"
        transferAmountLabel.font = UIFont.systemFont(ofSize: 14)
        transferAmountLabel.textColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        fundsRow.addSubview(transferAmountLabel)
        transferAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 分割线
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        view.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        
        // 卡片列表滚动区
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .vertical
        stackView.spacing = 12
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加储蓄卡按钮
        addCardButton.setTitle("添加储蓄卡", for: .normal)
        addCardButton.setTitleColor(.white, for: .normal)
        addCardButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        addCardButton.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        addCardButton.layer.cornerRadius = 8
        addCardButton.addTarget(self, action: #selector(addCardTapped), for: .touchUpInside)
        view.addSubview(addCardButton)
        addCardButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 说明规则
        tip1Label.text = "1.新用户注册后必须通过添加银行卡。"
        tip1Label.font = UIFont.systemFont(ofSize: 12)
        tip1Label.textColor = Constants.Color.textTertiary
        tip1Label.numberOfLines = 0
        view.addSubview(tip1Label)
        tip1Label.translatesAutoresizingMaskIntoConstraints = false
        
        tip2Label.text = "2.真实姓名必须和绑定银行卡户名一样。"
        tip2Label.font = UIFont.systemFont(ofSize: 12)
        tip2Label.textColor = Constants.Color.textTertiary
        tip2Label.numberOfLines = 0
        view.addSubview(tip2Label)
        tip2Label.translatesAutoresizingMaskIntoConstraints = false
        
        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            // 资金行
            fundsRow.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            fundsRow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            fundsRow.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            fundsRow.heightAnchor.constraint(equalToConstant: 44),
            
            t1Label.leadingAnchor.constraint(equalTo: fundsRow.leadingAnchor, constant: 16),
            t1Label.centerYAnchor.constraint(equalTo: fundsRow.centerYAnchor),
            
            t1AmountLabel.leadingAnchor.constraint(equalTo: t1Label.trailingAnchor, constant: 8),
            t1AmountLabel.centerYAnchor.constraint(equalTo: fundsRow.centerYAnchor),
            
            transferAmountLabel.trailingAnchor.constraint(equalTo: fundsRow.trailingAnchor, constant: -16),
            transferAmountLabel.centerYAnchor.constraint(equalTo: fundsRow.centerYAnchor),
            
            transferLabel.trailingAnchor.constraint(equalTo: transferAmountLabel.leadingAnchor, constant: -8),
            transferLabel.centerYAnchor.constraint(equalTo: fundsRow.centerYAnchor),
            
            // 分割线
            divider.topAnchor.constraint(equalTo: fundsRow.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            
            // 卡片列表
            scrollView.topAnchor.constraint(equalTo: divider.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: addCardButton.topAnchor, constant: -12),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -12),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -24),
            
            // 添加储蓄卡按钮
            addCardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            addCardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            addCardButton.heightAnchor.constraint(equalToConstant: 48),
            addCardButton.bottomAnchor.constraint(equalTo: tip1Label.topAnchor, constant: -12),
            
            // 说明规则
            tip1Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tip1Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tip1Label.bottomAnchor.constraint(equalTo: tip2Label.topAnchor, constant: -6),
            
            tip2Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tip2Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tip2Label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }
    
    // MARK: - 构建银行卡卡片视图（对齐安卓 item_bank_card.xml）
    private func createCardView(for card: BankCard) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 8
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 1)
        container.layer.shadowRadius = 4
        container.layer.shadowOpacity = 0.05
        
        // 银行名称（粗体）
        let bankNameLabel = UILabel()
        bankNameLabel.text = card.displayBankName
        bankNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        bankNameLabel.textColor = UIColor(red: 0.19, green: 0.19, blue: 0.19, alpha: 1.0)
        container.addSubview(bankNameLabel)
        bankNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 修改按钮
        let editBtn = UIButton(type: .system)
        editBtn.setTitle("修改", for: .normal)
        editBtn.setTitleColor(.white, for: .normal)
        editBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        editBtn.backgroundColor = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        editBtn.layer.cornerRadius = 4
        editBtn.tag = card.id
        editBtn.addTarget(self, action: #selector(editCardTapped(_:)), for: .touchUpInside)
        container.addSubview(editBtn)
        editBtn.translatesAutoresizingMaskIntoConstraints = false
        
        // 脱敏卡号
        let cardNoLabel = UILabel()
        cardNoLabel.text = card.displayCardNumber
        cardNoLabel.font = UIFont.systemFont(ofSize: 15)
        cardNoLabel.textColor = UIColor(red: 0.38, green: 0.38, blue: 0.38, alpha: 1.0)
        container.addSubview(cardNoLabel)
        cardNoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 开户支行
        let branchLabel = UILabel()
        branchLabel.text = "开户支行：\(card.khzhihang.isEmpty ? "-" : card.khzhihang)"
        branchLabel.font = UIFont.systemFont(ofSize: 13)
        branchLabel.textColor = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.0)
        container.addSubview(branchLabel)
        branchLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bankNameLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            bankNameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            bankNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: editBtn.leadingAnchor, constant: -8),
            
            editBtn.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            editBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            editBtn.widthAnchor.constraint(equalToConstant: 56),
            editBtn.heightAnchor.constraint(equalToConstant: 28),
            
            cardNoLabel.topAnchor.constraint(equalTo: bankNameLabel.bottomAnchor, constant: 12),
            cardNoLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            cardNoLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            
            branchLabel.topAnchor.constraint(equalTo: cardNoLabel.bottomAnchor, constant: 6),
            branchLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            branchLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            branchLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
        ])
        
        return container
    }
    
    // MARK: - Data
    private func loadData() {
        Task {
            do {
                SVProgressHUD.show()
                
                // 加载余额数据（对齐安卓 getUserPriceAll）
                do {
                    let priceResult = try await SecureNetworkManager.shared.request(api: "/api/user/getUserPrice_all", method: .get, params: [:])
                    if let priceDict = priceResult.decrypted,
                       let priceData = priceDict["data"] as? [String: Any] {
                        print("【银行卡】getUserPriceAll data: \(priceData)")
                        // 对齐安卓：data.list 包含 freeze_profit 和 balance
                        let priceInfo: [String: Any]?
                        if let list = priceData["list"] as? [String: Any] {
                            priceInfo = list
                        } else {
                            // 备选：直接从 data 层读取
                            priceInfo = priceData
                        }
                        if let info = priceInfo {
                            let freezeProfit = Double("\(info["freeze_profit"] ?? 0)") ?? 0
                            let balance = Double("\(info["balance"] ?? 0)") ?? 0
                            print("【银行卡】freeze_profit=\(freezeProfit), balance=\(balance)")
                            DispatchQueue.main.async {
                                self.t1AmountLabel.text = self.formatAmount(freezeProfit)
                                self.transferAmountLabel.text = self.formatAmount(balance)
                            }
                        }
                    } else {
                        print("【银行卡】getUserPriceAll 解密失败或无 data")
                    }
                } catch {
                    print("【银行卡】getUserPriceAll 请求失败: \(error.localizedDescription)")
                }
                
                // 加载银行卡列表
                let result = try await SecureNetworkManager.shared.request(api: Api.accountLst_api, method: .post, params: [:])
                await SVProgressHUD.dismiss()
                
                guard let dict = result.decrypted else {
                    debugPrint("[银行卡] 解密失败")
                    DispatchQueue.main.async { self.updateUI() }
                    return
                }
                
                if let msg = dict["msg"] as? String, msg != "success" {
                    debugPrint("[银行卡] API 返回错误：\(msg)")
                    DispatchQueue.main.async {
                        Toast.showInfo(msg)
                        self.updateUI()
                    }
                    return
                }
                
                guard let data = dict["data"] as? [String: Any] else {
                    debugPrint("[银行卡] data 字段解析失败")
                    DispatchQueue.main.async { self.updateUI() }
                    return
                }
                
                // 最大绑卡数
                if let bindkanums = data["bindkanums"] as? String, let max = Int(bindkanums) {
                    self.maxCards = max
                }
                
                // 解析银行卡列表
                var cardsList: Any?
                if let listDict = data["list"] as? [String: Any] {
                    cardsList = listDict["data"]
                } else if let listArray = data["list"] as? [[String: Any]] {
                    cardsList = listArray
                }
                if cardsList == nil, let directData = data["data"] as? [[String: Any]] {
                    cardsList = directData
                }
                
                guard let cardsData = cardsList else {
                    debugPrint("[银行卡] 银行卡列表解析失败")
                    DispatchQueue.main.async { self.updateUI() }
                    return
                }
                
                let jsonData = try JSONSerialization.data(withJSONObject: cardsData, options: [])
                let cards = try JSONDecoder().decode([BankCard].self, from: jsonData)
                self.bankCards = cards
                
                DispatchQueue.main.async { self.updateUI() }
                
            } catch {
                await SVProgressHUD.dismiss()
                debugPrint("[银行卡] 异常:", error.localizedDescription)
                Toast.showError(error.localizedDescription)
                DispatchQueue.main.async { self.updateUI() }
            }
        }
    }
    
    private func formatAmount(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value))"
        }
        return String(format: "%.2f", value)
    }
    
    private func updateUI() {
        // 清空旧卡片
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 添加卡片
        for card in bankCards {
            let cardView = createCardView(for: card)
            stackView.addArrangedSubview(cardView)
        }
        
        // 对齐安卓：已绑卡数 >= 最大绑卡数时隐藏添加按钮
        addCardButton.isHidden = bankCards.count >= maxCards
    }
    
    // MARK: - Actions
    @objc private func addCardTapped() {
        let vc = BindBankCardViewController()
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func editCardTapped(_ sender: UIButton) {
        let cardId = sender.tag
        guard let card = bankCards.first(where: { $0.id == cardId }) else { return }
        let vc = BindBankCardViewController()
        vc.bankCard = card
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
