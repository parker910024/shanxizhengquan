//
//  BankTransferInViewController.swift
//  zhengqaun
//
//  银证转入详情页：复刻安卓 TransferInDetailActivity UI 与逻辑
//

import UIKit
import SafariServices

class BankTransferInViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // UI 组件
    private let rangeHintLabel = UILabel()
    private let amountInputContainer = UIView()
    private let yenLabel = UILabel()
    private let amountTextField = UITextField()
    private let dividerLine = UIView()
    private let minHintLabel = UILabel()
    
    // 快捷金额
    private let fixedAmountContainer = UIView()
    private let fixedAmountTitleLabel = UILabel()
    private let fixedAmountStackView = UIStackView()
    private var amountButtons: [UIButton] = []
    
    // 按钮
    private let transferButton = UIButton(type: .system)
    
    // 属性
    var sysbankId: Int?
    var minLimit: Double = 100
    var maxLimit: Double = 100000
    var channelName: String = ""
    var yzmima: String = ""
    var urlType: Int = 2  // 1=内置WebView, 其他=外部浏览器
    
    private var supportCustomAmount = true
    private var fixedAmounts: [Int] = []
    private var selectedAmount: Int?
    
    private var defaultTop: NSLayoutConstraint?
    private var fallbackTop: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupUI()
        loadChannelConfig()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = channelName.isEmpty ? "银证转入" : channelName
        gk_navLineHidden = false
        gk_backStyle = .black
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        // 修复顶部空白：禁止自动调整内边距，手动控制
        scrollView.contentInsetAdjustmentBehavior = .never
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: gk_navigationBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let pad: CGFloat = 16
        
        // 1. 金额范围提示
        rangeHintLabel.font = UIFont.systemFont(ofSize: 13)
        rangeHintLabel.textColor = Constants.Color.textSecondary
        rangeHintLabel.text = "载入中..."
        contentView.addSubview(rangeHintLabel)
        rangeHintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 2. 金额输入区容器
        contentView.addSubview(amountInputContainer)
        amountInputContainer.translatesAutoresizingMaskIntoConstraints = false
        
        yenLabel.text = "¥"
        yenLabel.font = UIFont.boldSystemFont(ofSize: 24)
        yenLabel.textColor = Constants.Color.textPrimary
        amountInputContainer.addSubview(yenLabel)
        yenLabel.translatesAutoresizingMaskIntoConstraints = false
        
        amountTextField.placeholder = "请输入转入金额"
        amountTextField.font = UIFont.systemFont(ofSize: 18)
        amountTextField.textColor = Constants.Color.textPrimary
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .none
        amountTextField.delegate = self
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        amountInputContainer.addSubview(amountTextField)
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 3. 分隔线
        dividerLine.backgroundColor = UIColor(hexString: "EEEEEE")
        contentView.addSubview(dividerLine)
        dividerLine.translatesAutoresizingMaskIntoConstraints = false
        
        // 4. 最小金额提示
        minHintLabel.font = UIFont.systemFont(ofSize: 13)
        minHintLabel.textColor = Constants.Color.textSecondary
        contentView.addSubview(minHintLabel)
        minHintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 5. 固定金额选择区域
        contentView.addSubview(fixedAmountContainer)
        fixedAmountContainer.translatesAutoresizingMaskIntoConstraints = false
        fixedAmountContainer.isHidden = true
        
        fixedAmountTitleLabel.text = "请选择以下金额"
        fixedAmountTitleLabel.font = UIFont.systemFont(ofSize: 13)
        fixedAmountTitleLabel.textColor = Constants.Color.textSecondary
        fixedAmountContainer.addSubview(fixedAmountTitleLabel)
        fixedAmountTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        fixedAmountStackView.axis = .horizontal
        fixedAmountStackView.distribution = .fillEqually
        fixedAmountStackView.spacing = 10
        fixedAmountContainer.addSubview(fixedAmountStackView)
        fixedAmountStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // 6. 确认转入按钮
        transferButton.setTitle("确认转入", for: .normal)
        transferButton.setTitleColor(.white, for: .normal)
        transferButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        transferButton.backgroundColor = Constants.Color.stockRise
        transferButton.layer.cornerRadius = 8
        transferButton.isEnabled = false
        transferButton.alpha = 0.5
        transferButton.addTarget(self, action: #selector(transferTapped), for: .touchUpInside)
        contentView.addSubview(transferButton)
        transferButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 初始化约束属性
        let dTop = minHintLabel.topAnchor.constraint(equalTo: dividerLine.bottomAnchor, constant: 8)
        let fTop = minHintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        self.defaultTop = dTop
        self.fallbackTop = fTop
        
        NSLayoutConstraint.activate([
            rangeHintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            rangeHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            amountInputContainer.topAnchor.constraint(equalTo: rangeHintLabel.bottomAnchor, constant: 20),
            amountInputContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            amountInputContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            amountInputContainer.heightAnchor.constraint(equalToConstant: 48),
            
            yenLabel.leadingAnchor.constraint(equalTo: amountInputContainer.leadingAnchor),
            yenLabel.centerYAnchor.constraint(equalTo: amountInputContainer.centerYAnchor),
            
            amountTextField.leadingAnchor.constraint(equalTo: yenLabel.trailingAnchor, constant: 12),
            amountTextField.trailingAnchor.constraint(equalTo: amountInputContainer.trailingAnchor),
            amountTextField.centerYAnchor.constraint(equalTo: amountInputContainer.centerYAnchor),
            
            dividerLine.topAnchor.constraint(equalTo: amountInputContainer.bottomAnchor),
            dividerLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            dividerLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            dividerLine.heightAnchor.constraint(equalToConstant: 1),
            
            dTop, // 默认激活 defaultTop
            minHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            
            fixedAmountContainer.topAnchor.constraint(equalTo: minHintLabel.bottomAnchor, constant: 16),
            fixedAmountContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            fixedAmountContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            
            fixedAmountTitleLabel.topAnchor.constraint(equalTo: fixedAmountContainer.topAnchor),
            fixedAmountTitleLabel.leadingAnchor.constraint(equalTo: fixedAmountContainer.leadingAnchor),
            
            fixedAmountStackView.topAnchor.constraint(equalTo: fixedAmountTitleLabel.bottomAnchor, constant: 12),
            fixedAmountStackView.leadingAnchor.constraint(equalTo: fixedAmountContainer.leadingAnchor),
            fixedAmountStackView.trailingAnchor.constraint(equalTo: fixedAmountContainer.trailingAnchor),
            fixedAmountStackView.bottomAnchor.constraint(equalTo: fixedAmountContainer.bottomAnchor),
            fixedAmountStackView.heightAnchor.constraint(equalToConstant: 44),
            
            transferButton.topAnchor.constraint(equalTo: fixedAmountContainer.bottomAnchor, constant: 40),
            transferButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            transferButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            transferButton.heightAnchor.constraint(equalToConstant: 48),
            transferButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func loadChannelConfig() {
        guard let channelId = sysbankId else { return }
        SecureNetworkManager.shared.request(
            api: "/api/index/getyhkconfignew",
            method: .get,
            params: ["bankid": channelId]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any] else { return }
                
                let chargeLow = Double("\(data["charge_low"] ?? "100")") ?? 100.0
                self.minLimit = chargeLow
                
                if let list = data["list"] as? [[String: Any]], let channel = list.first {
                    self.minLimit = Double("\(channel["minlow"] ?? "\(chargeLow)")") ?? chargeLow
                    self.maxLimit = Double("\(channel["maxhigh"] ?? "100000")") ?? 100000.0
                    self.yzmima = channel["yzmima"] as? String ?? ""
                    let accountConfig = channel["account"] as? String ?? ""
                    self.applyAmountConfig(accountConfig)
                }
                
                DispatchQueue.main.async {
                    self.updateAmountHints()
                }
            case .failure(let err):
                debugPrint("加载配置错误:", err.localizedDescription)
            }
        }
    }
    
    private func applyAmountConfig(_ accountConfig: String) {
        if accountConfig.isEmpty {
            supportCustomAmount = true
            fixedAmounts = []
        } else {
            let parsed = accountConfig.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            fixedAmounts = parsed.filter { $0 > 0 }
            supportCustomAmount = parsed.contains(0) || parsed.isEmpty
        }
        
        DispatchQueue.main.async {
            self.buildFixedAmountButtons()
            if !self.supportCustomAmount && !self.fixedAmounts.isEmpty {
                self.amountInputContainer.isHidden = true
                self.dividerLine.isHidden = true
                self.rangeHintLabel.isHidden = true
                
                // 稳健切换：直接操作属性
                self.defaultTop?.isActive = false
                self.fallbackTop?.isActive = true
                
                self.fixedAmountTapped(self.amountButtons.first!)
            } else {
                self.amountInputContainer.isHidden = false
                self.dividerLine.isHidden = false
                self.rangeHintLabel.isHidden = false
                
                // 还原
                self.fallbackTop?.isActive = false
                self.defaultTop?.isActive = true
            }
            self.fixedAmountContainer.isHidden = self.fixedAmounts.isEmpty
        }
    }
    
    private func buildFixedAmountButtons() {
        amountButtons.forEach { $0.removeFromSuperview() }
        amountButtons.removeAll()
        
        for amount in fixedAmounts {
            let btn = UIButton(type: .custom)
            btn.setTitle("\(amount)", for: .normal)
            btn.setTitleColor(UIColor(hexString: "333333"), for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            btn.backgroundColor = UIColor(hexString: "F5F5F5")
            btn.layer.cornerRadius = 6
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor(hexString: "DDDDDD")?.cgColor
            btn.addTarget(self, action: #selector(fixedAmountTapped(_:)), for: .touchUpInside)
            fixedAmountStackView.addArrangedSubview(btn)
            amountButtons.append(btn)
        }
    }
    
    private func updateAmountHints() {
        rangeHintLabel.text = "转入金额范围：\(Int(minLimit)) - \(Int(maxLimit)) 元"
        minHintLabel.text = "最小转入金额为 \(Int(minLimit)) 元"
    }
    
    @objc private func amountChanged() {
        updateSubmitButtonState()
        // 手动输入时取消按钮选中态
        if let currentText = amountTextField.text, !currentText.isEmpty {
            let amount = Int(currentText)
            updateButtonsSelection(selectedAmount: amount)
        } else {
            updateButtonsSelection(selectedAmount: nil)
        }
    }
    
    private func updateSubmitButtonState() {
        let text = amountTextField.text ?? ""
        let val = Double(text) ?? 0
        let isEnabled = val >= minLimit && val <= maxLimit
        transferButton.isEnabled = isEnabled
        transferButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    @objc private func fixedAmountTapped(_ sender: UIButton) {
        let amountStr = sender.currentTitle ?? ""
        amountTextField.text = amountStr
        selectedAmount = Int(amountStr)
        updateButtonsSelection(selectedAmount: selectedAmount)
        updateSubmitButtonState()
    }
    
    private func updateButtonsSelection(selectedAmount: Int?) {
        for btn in amountButtons {
            let btnAmount = Int(btn.currentTitle ?? "")
            let isSelected = btnAmount == selectedAmount
            if isSelected {
                btn.backgroundColor = Constants.Color.stockRise
                btn.setTitleColor(.white, for: .normal)
                btn.layer.borderColor = Constants.Color.stockRise.cgColor
            } else {
                btn.backgroundColor = UIColor(hexString: "F5F5F5")
                btn.setTitleColor(UIColor(hexString: "333333"), for: .normal)
                btn.layer.borderColor = UIColor(hexString: "DDDDDD")?.cgColor
            }
        }
    }
    
    @objc private func transferTapped() {
        guard let text = amountTextField.text, let val = Double(text) else { return }
        
        if !yzmima.isEmpty {
            showPasswordInput { [weak self] pwd in
                self?.doRecharge(amount: val, password: pwd)
            }
        } else {
            doRecharge(amount: val, password: nil)
        }
    }
    
    private func showPasswordInput(completion: @escaping (String) -> Void) {
        let passwordView = PaymentPasswordInputView()
        passwordView.onComplete = completion
        passwordView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordView)
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.topAnchor.constraint(equalTo: view.topAnchor),
            passwordView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func doRecharge(amount: Double, password: String?) {
        guard let bankId = sysbankId else { return }
        transferButton.isEnabled = false
        
        var params: [String: Any] = [
            "money": String(format: amount == floor(amount) ? "%.0f" : "%.2f", amount),
            "sysbankid": bankId,
            "pay_type": 3
        ]
        if let pwd = password {
            params["pass"] = pwd
        }
        
        SecureNetworkManager.shared.request(
            api: "/api/user/recharge",
            method: .post,
            params: params
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.transferButton.isEnabled = true
                switch result {
                case .success(let res):
                    guard let dict = res.decrypted else {
                        Toast.show("转入失败")
                        return
                    }
                    let retCode = dict["retCode"] as? Int ?? -1
                    if retCode == 0 {
                        // 对齐安卓：检查 payJumpUrl，有则跳转 H5 支付页面
                        let jumpUrl = (dict["payJumpUrl"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !jumpUrl.isEmpty, var urlStr = Optional(jumpUrl) {
                            if !urlStr.hasPrefix("http") {
                                urlStr = "https://" + urlStr
                            }
                            if let url = URL(string: urlStr) {
                                if self.urlType == 1 {
                                    // 内置 WebView 打开
                                    let safari = SFSafariViewController(url: url)
                                    self.present(safari, animated: true)
                                } else {
                                    // 外部浏览器打开
                                    UIApplication.shared.open(url)
                                }
                            }
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            Toast.show(dict["retMsg"] as? String ?? "转入申请已提交")
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        Toast.show(dict["retMsg"] as? String ?? "转入失败")
                    }
                case .failure(let err):
                    Toast.show(err.localizedDescription)
                }
            }
        }
    }
}

extension BankTransferInViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // 限制只能输入数字和小数点
        let allowed = CharacterSet(charactersIn: "0123456789.")
        return string.rangeOfCharacter(from: allowed.inverted) == nil
    }
}

