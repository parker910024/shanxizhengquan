//
//  BankSecuritiesTransferViewController.swift
//  zhengqaun
//
//  转出页：严格按 UI 图，仅含导航栏、T+1/可转出、金额输入、全部提现、转出按钮。
//

import UIKit

class BankSecuritiesTransferViewController: ZQViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let orangeRed = UIColor(red: 0.92, green: 0.35, blue: 0.14, alpha: 1.0)
    
    // 资金显示
    private let t1ValueLabel = UILabel()
    private let outValueLabel = UILabel()
    private let amountField = UITextField()
    private var availableBalance: Double = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavBar()
        setupScrollView()
        setupContent()
        loadFundData()
    }

    private func setupNavBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "转出"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        gk_backStyle = .black
       
    }

    @objc private func searchTapped() {}

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let navH = Constants.Navigation.totalNavigationHeight
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navH),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupContent() {
        let pad: CGFloat = 16
        let redColor = Constants.Color.stockRise

        // 一行两列：T+1资金 0.00（左）| 可转出金额 0.00（右），整块红色
        let fundRow = UIView()
        let t1Label = UILabel()
        t1Label.text = "T+1资金"
        t1Label.font = UIFont.systemFont(ofSize: 15)
        t1Label.textColor = redColor
        fundRow.addSubview(t1Label)
        t1Label.translatesAutoresizingMaskIntoConstraints = false
        let t1Value = t1ValueLabel
        t1Value.text = "0.00"
        t1Value.font = UIFont.systemFont(ofSize: 15)
        t1Value.textColor = redColor
        fundRow.addSubview(t1Value)
        t1Value.translatesAutoresizingMaskIntoConstraints = false
        let outLabel = UILabel()
        outLabel.text = "可转出金额"
        outLabel.font = UIFont.systemFont(ofSize: 15)
        outLabel.textColor = redColor
        fundRow.addSubview(outLabel)
        outLabel.translatesAutoresizingMaskIntoConstraints = false
        let outValue = outValueLabel
        outValue.text = "0.00"
        outValue.font = UIFont.systemFont(ofSize: 15)
        outValue.textColor = redColor
        fundRow.addSubview(outValue)
        outValue.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            t1Label.leadingAnchor.constraint(equalTo: fundRow.leadingAnchor),
            t1Label.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor),
            t1Value.leadingAnchor.constraint(equalTo: t1Label.trailingAnchor, constant: 4),
            t1Value.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor),
            outValue.trailingAnchor.constraint(equalTo: fundRow.trailingAnchor),
            outValue.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor),
            outLabel.trailingAnchor.constraint(equalTo: outValue.leadingAnchor, constant: -4),
            outLabel.centerYAnchor.constraint(equalTo: fundRow.centerYAnchor)
        ])
        contentView.addSubview(fundRow)
        fundRow.translatesAutoresizingMaskIntoConstraints = false

        // ¥ + 请输入转出金额
        let inputRow = UIView()
        let yenLbl = UILabel()
        yenLbl.text = "¥"
        yenLbl.font = UIFont.systemFont(ofSize: 20)
        yenLbl.textColor = Constants.Color.textPrimary
        inputRow.addSubview(yenLbl)
        yenLbl.translatesAutoresizingMaskIntoConstraints = false
        let amountField = self.amountField
        amountField.placeholder = "请输入转出金额"
        amountField.font = UIFont.systemFont(ofSize: 18)
        amountField.textColor = Constants.Color.textPrimary
        amountField.keyboardType = .decimalPad
        amountField.attributedPlaceholder = NSAttributedString(string: "请输入转出金额", attributes: [.foregroundColor: Constants.Color.textTertiary])
        inputRow.addSubview(amountField)
        amountField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            yenLbl.leadingAnchor.constraint(equalTo: inputRow.leadingAnchor),
            yenLbl.centerYAnchor.constraint(equalTo: inputRow.centerYAnchor),
            amountField.leadingAnchor.constraint(equalTo: yenLbl.trailingAnchor, constant: 8),
            amountField.trailingAnchor.constraint(equalTo: inputRow.trailingAnchor),
            amountField.centerYAnchor.constraint(equalTo: inputRow.centerYAnchor),
            amountField.heightAnchor.constraint(equalToConstant: 44)
        ])
        contentView.addSubview(inputRow)
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        // 全部提现（红色）
        let withdrawAllBtn = UIButton(type: .system)
        withdrawAllBtn.setTitle("全部提现", for: .normal)
        withdrawAllBtn.setTitleColor(redColor, for: .normal)
        withdrawAllBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        withdrawAllBtn.addTarget(self, action: #selector(withdrawAllTapped), for: .touchUpInside)
        contentView.addSubview(withdrawAllBtn)
        withdrawAllBtn.translatesAutoresizingMaskIntoConstraints = false

        // 转出按钮（橙红底白字）
        let submit = UIButton(type: .system)
        submit.setTitle("转出", for: .normal)
        submit.setTitleColor(.white, for: .normal)
        submit.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submit.backgroundColor = orangeRed
        submit.layer.cornerRadius = 8
        submit.addTarget(self, action: #selector(transferOutTapped), for: .touchUpInside)
        contentView.addSubview(submit)
        submit.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            fundRow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
            fundRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            fundRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            fundRow.heightAnchor.constraint(equalToConstant: 44),

            inputRow.topAnchor.constraint(equalTo: fundRow.bottomAnchor, constant: 24),
            inputRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            inputRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            inputRow.heightAnchor.constraint(equalToConstant: 48),

            withdrawAllBtn.topAnchor.constraint(equalTo: inputRow.bottomAnchor, constant: 8),
            withdrawAllBtn.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),

            submit.topAnchor.constraint(equalTo: withdrawAllBtn.bottomAnchor, constant: 32),
            submit.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            submit.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),
            submit.heightAnchor.constraint(equalToConstant: 48),
            submit.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    @objc private func withdrawAllTapped() {
        // 填充全部可转出余额
        amountField.text = String(format: "%.2f", availableBalance)
    }

    @objc private func transferOutTapped() {
        // 校验金额
        guard let text = amountField.text, let amount = Double(text), amount > 0 else {
            Toast.show("请输入有效的转出金额")
            return
        }
        if amount > availableBalance {
            Toast.show("转出金额不能超过可转出余额")
            return
        }
        
        let passwordView = PaymentPasswordInputView()
        passwordView.onComplete = { [weak self] password in
            self?.submitWithdraw(amount: amount, password: password)
        }
        passwordView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(passwordView)
        NSLayoutConstraint.activate([
            passwordView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            passwordView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            passwordView.topAnchor.constraint(equalTo: view.topAnchor),
            passwordView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - 加载资金数据
    private func loadFundData() {
        SecureNetworkManager.shared.request(
            api: "/api/user/capitalLog",
            method: .get,
            params: ["type": "1"]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let userInfo = data["userInfo"] as? [String: Any] else { return }
                
                let balance = userInfo["balance"] as? Double ?? 0
                let freezeProfit = userInfo["freeze_profit"] as? Double ?? 0
                
                self.availableBalance = balance
                self.t1ValueLabel.text = String(format: "%.2f", freezeProfit)
                self.outValueLabel.text = String(format: "%.2f", balance)
                
            case .failure(_): break
            }
        }
    }
    
    // MARK: - 提交转出
    private func submitWithdraw(amount: Double, password: String) {
        SecureNetworkManager.shared.request(
            api: "/api/user/applyWithdraw",
            method: .get,
            params: ["account_id": "1", "money": "\(amount)", "pass": password]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                if let dict = res.decrypted, let code = dict["code"] as? Int, code == 1 {
                    Toast.show("转出申请已提交")
                    self.amountField.text = ""
                    // 刷新余额
                    self.loadFundData()
                } else {
                    let msg = res.decrypted?["msg"] as? String ?? "转出失败"
                    Toast.show(msg)
                }
            case .failure(let error):
                Toast.show("请求失败: \(error.localizedDescription)")
            }
        }
    }
}
