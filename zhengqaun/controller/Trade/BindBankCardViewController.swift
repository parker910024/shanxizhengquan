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
    
    // 输入框容器
    private var bankContainer = UIView()
    private let bankLabel = UILabel()
    private let bankTextField = UITextField()
    
    private var branchContainer = UIView()
    private let branchLabel = UILabel()
    private let branchTextField = UITextField()

    private var cardNumberContainer = UIView()
    private let cardNumberLabel = UILabel()
    private let cardNumberTextField = UITextField()

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
        cardNumberTextField.text = card.cardNumber
        
        // 更新提交按钮状态
        updateSubmitButton()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "添加储蓄卡"
        gk_navLineHidden = false
        gk_statusBarStyle = .default
        gk_navItemLeftSpace = 15
        gk_navItemRightSpace = 15
        gk_backStyle = .black

    }

    @objc private func serviceTapped() {
        // 客服/帮助
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
        // 三个必填项：银行名称*、银行卡号*、开户支行*
        bankContainer = createTextFieldContainer(label: "银行名称", textField: bankTextField, placeholder: "请输入银行名称", required: true)
        contentView.addSubview(bankContainer)
        bankContainer.translatesAutoresizingMaskIntoConstraints = false

        cardNumberContainer = createTextFieldContainer(label: "银行卡号", textField: cardNumberTextField, placeholder: "请输入银行卡号", required: true)
        contentView.addSubview(cardNumberContainer)
        cardNumberContainer.translatesAutoresizingMaskIntoConstraints = false

        branchContainer = createTextFieldContainer(label: "开户支行", textField: branchTextField, placeholder: "请输入开户支行", required: true)
        contentView.addSubview(branchContainer)
        branchContainer.translatesAutoresizingMaskIntoConstraints = false

        submitButton.setTitle("确认", for: .normal)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        submitButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        submitButton.isEnabled = false
        contentView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bankContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            bankContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bankContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bankContainer.heightAnchor.constraint(equalToConstant: 50),

            cardNumberContainer.topAnchor.constraint(equalTo: bankContainer.bottomAnchor),
            cardNumberContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardNumberContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardNumberContainer.heightAnchor.constraint(equalToConstant: 50),

            branchContainer.topAnchor.constraint(equalTo: cardNumberContainer.bottomAnchor),
            branchContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            branchContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            branchContainer.heightAnchor.constraint(equalToConstant: 50),

            submitButton.topAnchor.constraint(equalTo: branchContainer.bottomAnchor, constant: 32),
            submitButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            submitButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        updateSubmitButton()
    }
    
    private func createTextFieldContainer(label: String, textField: UITextField, placeholder: String, required: Bool = false) -> UIView {
        let container = UIView()
        container.backgroundColor = .white

        let labelView = UILabel()
        labelView.font = UIFont.systemFont(ofSize: 15)
        if required {
            let attr = NSMutableAttributedString(string: label, attributes: [.foregroundColor: Constants.Color.textPrimary])
            attr.append(NSAttributedString(string: " *", attributes: [.foregroundColor: UIColor.red]))
            labelView.attributedText = attr
        } else {
            labelView.text = label
            labelView.textColor = Constants.Color.textPrimary
        }
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
    
    @objc private func textFieldDidChange() {
        updateSubmitButton()
    }
    
    private func updateSubmitButton() {
        let hasBank = !(bankTextField.text?.isEmpty ?? true)
        let hasBranch = !(branchTextField.text?.isEmpty ?? true)
        let hasCardNumber = !(cardNumberTextField.text?.isEmpty ?? true)
        let isValid = hasBank && hasBranch && hasCardNumber

        submitButton.isEnabled = isValid
        if isValid {
            submitButton.backgroundColor = UIColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
            submitButton.setTitleColor(.white, for: .normal)
        } else {
            submitButton.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
            submitButton.setTitleColor(UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0), for: .normal)
        }
    }
    
    @objc private func submitTapped() {
        guard let bank = bankTextField.text,
              let branch = branchTextField.text,
              let cardNumber = cardNumberTextField.text else {
            return
        }
        // TODO: 提交银行卡信息到接口
        Toast.showSuccess("绑定成功")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
