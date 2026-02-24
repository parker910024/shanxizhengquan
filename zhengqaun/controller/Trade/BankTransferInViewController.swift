//
//  BankTransferInViewController.swift
//  zhengqaun
//
//  单笔银证转入页面：从银证转入列表点击进入
//

import UIKit

class BankTransferInViewController: ZQViewController {
    
    private let amountTitleLabel = UILabel()
    private let amountHintLabel = UILabel()
    private let amountTextField = UITextField()
    private let transferButton = UIButton(type: .system)
    
    // 外部传入的通道信息（由银证转账列表页传入）
    var sysbankId: Int?
    var minLimit: Double = 100
    var maxLimit: Double = 0
    var channelName: String = ""
    var yzmima: String = ""  // 银证密码，非空时需要输入密码
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupUI()
        // 如果外部已传入 sysbankId 则直接使用，否则自行加载
        if sysbankId != nil {
            amountHintLabel.text = "最小转入金额为\(Int(minLimit))元"
        } else {
            loadConfig()
        }
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = Constants.Color.themeBlue
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "银证账户"
        gk_navLineHidden = true
    }
    
    private func setupUI() {
        let pad: CGFloat = 64
        
        // 标题：银证转入金额
        amountTitleLabel.text = "银证转入金额"
        amountTitleLabel.font = UIFont.systemFont(ofSize: 16)
        amountTitleLabel.textColor = Constants.Color.textPrimary
        view.addSubview(amountTitleLabel)
        amountTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 最小金额提示
        amountHintLabel.text = "最小转入金额为100元"
        amountHintLabel.font = UIFont.systemFont(ofSize: 13)
        amountHintLabel.textColor = Constants.Color.textTertiary
        view.addSubview(amountHintLabel)
        amountHintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 金额输入框
        amountTextField.placeholder = "请输入转入金额"
        amountTextField.font = UIFont.systemFont(ofSize: 16)
        amountTextField.textColor = Constants.Color.textPrimary
        amountTextField.keyboardType = .decimalPad
        amountTextField.borderStyle = .none
        amountTextField.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        amountTextField.layer.cornerRadius = 6
        amountTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        amountTextField.leftViewMode = .always
        view.addSubview(amountTextField)
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        
        // 转入按钮
        transferButton.setTitle("银证转入", for: .normal)
        transferButton.setTitleColor(Constants.Color.textPrimary, for: .normal)
        transferButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        transferButton.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        transferButton.layer.cornerRadius = 24
        transferButton.addTarget(self, action: #selector(transferTapped), for: .touchUpInside)
        view.addSubview(transferButton)
        transferButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            amountTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: pad),
            amountTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            
            amountHintLabel.centerYAnchor.constraint(equalTo: amountTitleLabel.centerYAnchor),
            amountHintLabel.leadingAnchor.constraint(equalTo: amountTitleLabel.trailingAnchor, constant: 8),
            
            amountTextField.topAnchor.constraint(equalTo: amountTitleLabel.bottomAnchor, constant: 16),
            amountTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            amountTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            amountTextField.heightAnchor.constraint(equalToConstant: 48),
            
            transferButton.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: 32),
            transferButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            transferButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            transferButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func loadConfig() {
        SecureNetworkManager.shared.request(
            api: "/api/index/getchargeconfignew",
            method: .get,
            params: [:]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                guard let dict = res.decrypted,
                      let data = dict["data"] as? [String: Any],
                      let list = data["sysbank_list"] as? [[String: Any]],
                      let firstBank = list.first else { return }
                
                self.sysbankId = firstBank["id"] as? Int
                let minLow = Double("\(firstBank["minlow"] ?? "100")") ?? 100.0
                self.minLimit = minLow
                self.yzmima = firstBank["yzmima"] as? String ?? ""
                
                DispatchQueue.main.async {
                    self.amountHintLabel.text = "最小转入金额为\(Int(minLow))元"
                    self.amountHintLabel.textColor = Constants.Color.textTertiary
                }
            case .failure(let err):
                print("加载银证转入配置失败:", err.localizedDescription)
            }
        }
    }
    
    @objc private func transferTapped() {
        guard let text = amountTextField.text, !text.isEmpty,
              let value = Double(text) else {
            Toast.show("请输入有效的数字")
            return
        }
        guard value >= minLimit else {
            Toast.show("最小转入金额为\(Int(minLimit))元")
            return
        }
        guard let bankId = sysbankId else {
            Toast.show("暂无可用的银证转入通道")
            return
        }

        // 根据 yzmima 字段判断是否需要密码
        if !yzmima.isEmpty {
            // 需要密码：弹出密码输入
            showPasswordInput { [weak self] password in
                self?.submitTransfer(amount: value, bankId: bankId, password: password)
            }
        } else {
            // 不需要密码：直接提交
            submitTransfer(amount: value, bankId: bankId, password: nil)
        }
    }

    /// 弹出支付密码输入（6位数字 + 自定义键盘）
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

    /// 提交银证转入请求
    private func submitTransfer(amount: Double, bankId: Int, password: String?) {
        transferButton.isEnabled = false
        var params: [String: Any] = ["money": "\(amount)", "sysbankid": bankId]
        if let pwd = password {
            params["pass"] = pwd
        }
        SecureNetworkManager.shared.request(
            api: "/api/user/recharge",
            method: .post,
            params: params
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.transferButton.isEnabled = true
                switch result {
                case .success(let res):
                    if let dict = res.decrypted {
                        let retCode = dict["retCode"] as? Int ?? -1
                        let retMsg = dict["retMsg"] as? String ?? ""
                        if retCode == 0 {
                            Toast.show("转入提交成功")
                            self?.navigationController?.popViewController(animated: true)
                        } else {
                            Toast.show(retMsg.isEmpty ? "转入异常" : retMsg)
                        }
                    } else {
                        Toast.show("转入异常(Code: \(res.statusCode))")
                    }
                case .failure(let err):
                    Toast.show("网络请求失败: \(err.localizedDescription)")
                }
            }
        }
    }
}


