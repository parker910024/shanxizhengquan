//
//  BindBankCardViewController.swift
//  zhengqaun
//
//  绑定银行卡页面
//

import UIKit

class BindBankCardViewController: ZQViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 银行卡信息（用于修改时回显）
    var bankCard: BankCard?
    
    // 提示文字
    private let hintLabel = UILabel()
    
    // 输入框容器
    private var bankContainer = UIView()
    private let bankLabel = UILabel()
    private let bankTextField = UITextField()
    
    private var branchContainer = UIView()
    private let branchLabel = UILabel()
    private let branchTextField = UITextField()
    
    private var cardholderContainer = UIView()
    private let cardholderLabel = UILabel()
    private let cardholderTextField = UITextField()
    
    private var cardNumberContainer = UIView()
    private let cardNumberLabel = UILabel()
    private let cardNumberTextField = UITextField()
    
    // 协议复选框
    private let agreementContainer = UIView()
    private let checkBox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    private let agreementLink = UIButton(type: .system)
    private var isAgreed = false
    
    // 提交按钮
    private let submitButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupScrollView()
        setupContent()
        loadBankCardData()
    }
    
    /// 加载银行卡数据（如果是修改模式）
    private func loadBankCardData() {
        guard let card = bankCard else {
            return
        }
        
        // 回显银行卡信息
        bankTextField.text = card.cardName
        branchTextField.text = card.branchName
        cardholderTextField.text = card.cardName // 持卡人通常是卡名
        cardNumberTextField.text = card.cardNumber
        
        // 更新提交按钮状态
        updateSubmitButton()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "绑定银行卡"
        gk_navLineHidden = true
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
    }
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupScrollView() {
        let navH = Constants.Navigation.totalNavigationHeight
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
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
        // 提示文字
        hintLabel.text = "请绑定账户本人银行卡"
        hintLabel.font = UIFont.systemFont(ofSize: 14)
        hintLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // 浅灰色
        contentView.addSubview(hintLabel)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 银行输入框
        bankContainer = createTextFieldContainer(label: "银行", textField: bankTextField, placeholder: "请输入")
        contentView.addSubview(bankContainer)
        bankContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 分行输入框
        branchContainer = createTextFieldContainer(label: "分行", textField: branchTextField, placeholder: "请输入")
        contentView.addSubview(branchContainer)
        branchContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 持卡人输入框
        cardholderContainer = createTextFieldContainer(label: "持卡人", textField: cardholderTextField, placeholder: "请输入")
        contentView.addSubview(cardholderContainer)
        cardholderContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 卡号输入框
        cardNumberContainer = createTextFieldContainer(label: "卡号", textField: cardNumberTextField, placeholder: "请输入")
        contentView.addSubview(cardNumberContainer)
        cardNumberContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 协议复选框
        setupAgreement()
        
        // 提交按钮
        submitButton.setTitle("提交", for: .normal)
        submitButton.setTitleColor(UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0), for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // 浅灰色
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.isEnabled = false // 初始状态禁用
        contentView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 提示文字
            hintLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            hintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // 银行输入框
            bankContainer.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 16),
            bankContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bankContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bankContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // 分行输入框
            branchContainer.topAnchor.constraint(equalTo: bankContainer.bottomAnchor),
            branchContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            branchContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            branchContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // 持卡人输入框
            cardholderContainer.topAnchor.constraint(equalTo: branchContainer.bottomAnchor),
            cardholderContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardholderContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardholderContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // 卡号输入框
            cardNumberContainer.topAnchor.constraint(equalTo: cardholderContainer.bottomAnchor),
            cardNumberContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardNumberContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardNumberContainer.heightAnchor.constraint(equalToConstant: 50),
            
            // 协议复选框
            agreementContainer.topAnchor.constraint(equalTo: cardNumberContainer.bottomAnchor, constant: 20),
            agreementContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            agreementContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            agreementContainer.heightAnchor.constraint(equalToConstant: 30),
            
            // 提交按钮
            submitButton.topAnchor.constraint(equalTo: agreementContainer.bottomAnchor, constant: 30),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 44),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // 初始化提交按钮状态（灰色禁用）
        updateSubmitButton()
    }
    
    private func createTextFieldContainer(label: String, textField: UITextField, placeholder: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        
        // 标签
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 15)
        labelView.textColor = Constants.Color.textPrimary
        container.addSubview(labelView)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        // 输入框
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 15)
        textField.textColor = Constants.Color.textPrimary
        textField.textAlignment = .right
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        container.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // 分隔线
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)
        container.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            textField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textField.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            textField.leadingAnchor.constraint(greaterThanOrEqualTo: labelView.trailingAnchor, constant: 16),
            
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        
        return container
    }
    
    private func setupAgreement() {
        agreementContainer.backgroundColor = .clear
        contentView.addSubview(agreementContainer)
        agreementContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 复选框
        checkBox.setImage(UIImage(systemName: "circle"), for: .normal)
        checkBox.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkBox.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        checkBox.addTarget(self, action: #selector(checkBoxTapped), for: .touchUpInside)
        agreementContainer.addSubview(checkBox)
        checkBox.translatesAutoresizingMaskIntoConstraints = false
        
        // 协议文字
        agreementLabel.text = "我已阅读并同意"
        agreementLabel.font = UIFont.systemFont(ofSize: 14)
        agreementLabel.textColor = Constants.Color.textPrimary
        agreementContainer.addSubview(agreementLabel)
        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 协议链接
        agreementLink.setTitle("《用户协议》", for: .normal)
        agreementLink.setTitleColor(.systemRed, for: .normal)
        agreementLink.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        agreementLink.addTarget(self, action: #selector(agreementLinkTapped), for: .touchUpInside)
        agreementContainer.addSubview(agreementLink)
        agreementLink.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            checkBox.leadingAnchor.constraint(equalTo: agreementContainer.leadingAnchor),
            checkBox.centerYAnchor.constraint(equalTo: agreementContainer.centerYAnchor),
            checkBox.widthAnchor.constraint(equalToConstant: 24),
            checkBox.heightAnchor.constraint(equalToConstant: 24),
            
            agreementLabel.leadingAnchor.constraint(equalTo: checkBox.trailingAnchor, constant: 8),
            agreementLabel.centerYAnchor.constraint(equalTo: agreementContainer.centerYAnchor),
            
            agreementLink.leadingAnchor.constraint(equalTo: agreementLabel.trailingAnchor, constant: 4),
            agreementLink.centerYAnchor.constraint(equalTo: agreementContainer.centerYAnchor)
        ])
    }
    
    @objc private func checkBoxTapped() {
        isAgreed.toggle()
        checkBox.isSelected = isAgreed
        updateSubmitButton()
    }
    
    @objc private func agreementLinkTapped() {
        // TODO: 跳转到用户协议页面
        print("跳转到用户协议页面")
    }
    
    @objc private func textFieldDidChange() {
        updateSubmitButton()
    }
    
    private func updateSubmitButton() {
        let hasBank = !(bankTextField.text?.isEmpty ?? true)
        let hasBranch = !(branchTextField.text?.isEmpty ?? true)
        let hasCardholder = !(cardholderTextField.text?.isEmpty ?? true)
        let hasCardNumber = !(cardNumberTextField.text?.isEmpty ?? true)
        
        let isValid = hasBank && hasBranch && hasCardholder && hasCardNumber && isAgreed
        
        submitButton.isEnabled = isValid
        if isValid {
            submitButton.backgroundColor = UIColor(red: 25/255, green: 118/255, blue: 210/255, alpha: 1.0) // 蓝色
            submitButton.setTitleColor(.white, for: .normal)
        } else {
            submitButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0) // 浅灰色
            submitButton.setTitleColor(UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0), for: .normal)
        }
    }
    
    @objc private func submitTapped() {
        // TODO: 提交银行卡信息
        guard let bank = bankTextField.text,
              let branch = branchTextField.text,
              let cardholder = cardholderTextField.text,
              let cardNumber = cardNumberTextField.text else {
            return
        }
        
        // 验证和提交逻辑
        print("提交银行卡信息: 银行=\(bank), 分行=\(branch), 持卡人=\(cardholder), 卡号=\(cardNumber)")
        
        // 提交成功后返回上一页
        Toast.showSuccess("绑定成功")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
