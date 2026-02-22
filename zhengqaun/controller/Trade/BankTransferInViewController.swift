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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNavigationBar()
        setupUI()
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
    
    @objc private func transferTapped() {
        // 这里可以增加输入校验和实际转入逻辑，目前先简单检查金额是否 >= 100
        guard let text = amountTextField.text,
              let value = Double(text),
              value >= 100 else {
            Toast.show("请输入不小于100的金额")
            return
        }
        // TODO: 调用实际转入接口
        Toast.show("银证转入提交成功（模拟）")
        navigationController?.popViewController(animated: true)
    }
}


