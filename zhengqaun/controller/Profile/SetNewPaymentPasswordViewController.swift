//
//  SetNewPaymentPasswordViewController.swift
//  zhengqaun
//
//  Created by admin on 2026/1/6.
//

import UIKit

class SetNewPaymentPasswordViewController: ZQViewController {
    
    // 提示文字
    private let instructionLabel = UILabel()
    
    // 密码输入框容器
    private let passwordContainer = UIView()
    private var passwordLabels: [UILabel] = []
    
    // 数字键盘
    private let keypadContainer = UIView()
    
    // 密码
    private var password: String = "" {
        didSet {
            updatePasswordLabels()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }
    
    private func setupNavigationBar() {
        gk_navBackgroundColor = UIColor(red: 0.1, green: 0.47, blue: 0.82, alpha: 1.0)
        gk_navTintColor = .white
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = .white
        gk_navTitle = "请输入新支付密码"
        gk_navLineHidden = true
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        setupInstruction()
        setupPasswordInput()
        setupKeypad()
    }
    
    // MARK: - 提示文字
    private func setupInstruction() {
        instructionLabel.text = "请输入新支付密码"
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.textColor = Constants.Color.textPrimary
        instructionLabel.textAlignment = .center
        view.addSubview(instructionLabel)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight + 200),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - 密码输入框
    private func setupPasswordInput() {
        passwordContainer.backgroundColor = .white
        view.addSubview(passwordContainer)
        passwordContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 创建6个密码输入框（显示数字）
        let labelWidth: CGFloat = 40
        let labelSpacing: CGFloat = 10
        let totalWidth = CGFloat(6) * labelWidth + CGFloat(5) * labelSpacing
        
        for i in 0..<6 {
            let label = UILabel()
            label.text = ""
            label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            label.textColor = Constants.Color.textPrimary
            label.textAlignment = .center
            label.backgroundColor = .white
            label.layer.borderWidth = 1
            label.layer.borderColor = Constants.Color.separator.cgColor
            label.layer.cornerRadius = 4
            passwordContainer.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            passwordLabels.append(label)
        }
        
        NSLayoutConstraint.activate([
            passwordContainer.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 40),
            passwordContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            passwordContainer.heightAnchor.constraint(equalToConstant: 50),
            passwordContainer.widthAnchor.constraint(equalToConstant: totalWidth)
        ])
        
        // 设置6个输入框的约束
        for (index, label) in passwordLabels.enumerated() {
            NSLayoutConstraint.activate([
                label.widthAnchor.constraint(equalToConstant: labelWidth),
                label.heightAnchor.constraint(equalToConstant: 50),
                label.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor)
            ])
            
            if index == 0 {
                label.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor).isActive = true
            } else {
                label.leadingAnchor.constraint(equalTo: passwordLabels[index - 1].trailingAnchor, constant: labelSpacing).isActive = true
            }
        }
    }
    
    private func updatePasswordLabels() {
        for (index, label) in passwordLabels.enumerated() {
            if index < password.count {
                // 显示数字
                let index = password.index(password.startIndex, offsetBy: index)
                label.text = String(password[index])
            } else {
                // 未输入时显示空
                label.text = ""
            }
        }
        
        // 如果输入了6位密码，保存并返回
        if password.count == 6 {
            savePassword()
        }
    }
    
    // MARK: - 数字键盘
    private func setupKeypad() {
        keypadContainer.backgroundColor = .white
        view.addSubview(keypadContainer)
        keypadContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // 键盘按钮
        let buttons: [(String, Selector)] = [
            ("1", #selector(keypadButtonTapped(_:))),
            ("2", #selector(keypadButtonTapped(_:))),
            ("3", #selector(keypadButtonTapped(_:))),
            ("4", #selector(keypadButtonTapped(_:))),
            ("5", #selector(keypadButtonTapped(_:))),
            ("6", #selector(keypadButtonTapped(_:))),
            ("7", #selector(keypadButtonTapped(_:))),
            ("8", #selector(keypadButtonTapped(_:))),
            ("9", #selector(keypadButtonTapped(_:))),
            ("取消", #selector(cancelButtonTapped)),
            ("0", #selector(keypadButtonTapped(_:))),
            ("删除", #selector(deleteButtonTapped))
        ]
        
        let buttonWidth: CGFloat = (UIScreen.main.bounds.width - 2 * 16) / 3
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 0
        
        for (index, buttonInfo) in buttons.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(buttonInfo.0, for: .normal)
            button.setTitleColor(Constants.Color.textPrimary, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            
            // 取消和删除按钮使用灰色背景
            if buttonInfo.0 == "取消" || buttonInfo.0 == "删除" {
                button.backgroundColor = Constants.Color.backgroundMain
                button.setTitleColor(Constants.Color.textSecondary, for: .normal)
                if buttonInfo.0 == "删除" {
                    // 删除图标
                    let deleteIcon = UIImage(systemName: "delete.backward")
                    button.setImage(deleteIcon, for: .normal)
                    button.setTitle(nil, for: .normal)
                    button.tintColor = Constants.Color.textSecondary
                }
            } else {
                button.backgroundColor = .white
            }
            
            button.addTarget(self, action: buttonInfo.1, for: .touchUpInside)
            button.tag = index
            keypadContainer.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            let row = index / 3
            let col = index % 3
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: keypadContainer.leadingAnchor, constant: CGFloat(col) * (buttonWidth + spacing)),
                button.topAnchor.constraint(equalTo: keypadContainer.topAnchor, constant: CGFloat(row) * (buttonHeight + spacing)),
                button.widthAnchor.constraint(equalToConstant: buttonWidth),
                button.heightAnchor.constraint(equalToConstant: buttonHeight)
            ])
        }
        
        // 添加分割线
        for i in 1..<4 {
            let vLine = UIView()
            vLine.backgroundColor = Constants.Color.separator
            keypadContainer.addSubview(vLine)
            vLine.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                vLine.leadingAnchor.constraint(equalTo: keypadContainer.leadingAnchor, constant: CGFloat(i) * buttonWidth),
                vLine.topAnchor.constraint(equalTo: keypadContainer.topAnchor),
                vLine.bottomAnchor.constraint(equalTo: keypadContainer.bottomAnchor),
                vLine.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
            ])
        }
        
        for i in 1..<4 {
            let hLine = UIView()
            hLine.backgroundColor = Constants.Color.separator
            keypadContainer.addSubview(hLine)
            hLine.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                hLine.leadingAnchor.constraint(equalTo: keypadContainer.leadingAnchor),
                hLine.trailingAnchor.constraint(equalTo: keypadContainer.trailingAnchor),
                hLine.topAnchor.constraint(equalTo: keypadContainer.topAnchor, constant: CGFloat(i) * buttonHeight),
                hLine.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
            ])
        }
        
        NSLayoutConstraint.activate([
            keypadContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            keypadContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            keypadContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            keypadContainer.heightAnchor.constraint(equalToConstant: CGFloat(4) * buttonHeight)
        ])
    }
    
    // MARK: - Actions
    @objc private func keypadButtonTapped(_ sender: UIButton) {
        guard password.count < 6,
              let digit = sender.title(for: .normal) else {
            return
        }
        
        password += digit
    }
    
    @objc private func deleteButtonTapped() {
        if !password.isEmpty {
            password.removeLast()
        }
    }
    
    @objc private func cancelButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func savePassword() {
        // TODO: 保存新支付密码
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Toast.showInfo("新支付密码设置成功")
            // 返回上一页或首页
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}


