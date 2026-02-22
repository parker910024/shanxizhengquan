//
//  TransactionPasswordViewController.swift
//  zhengqaun
//
//  设置交易密码页面：标题 + 交易密码输入行（下划线）+ 红色确定按钮
//

import UIKit

class TransactionPasswordViewController: ZQViewController {

    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let passwordRow = UIView()
    private let passwordLabel = UILabel()
    private let passwordField = UITextField()
    private let underline = UIView()
    private let confirmButton = UIButton(type: .system)

    private var password: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()
    }

    private func setupNavigationBar() {
        gk_navBackgroundColor = .white
        gk_navTintColor = Constants.Color.textPrimary
        gk_navTitleFont = UIFont.boldSystemFont(ofSize: 17)
        gk_navTitleColor = Constants.Color.textPrimary
        gk_navTitle = "交易密码"
        gk_navLineHidden = false
        gk_backStyle = .black

    }

    @objc private func searchTapped() {
        // 可扩展：帮助或搜索
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // 大标题：设置交易密码
        titleLabel.text = "设置交易密码"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 22)
        titleLabel.textColor = Constants.Color.textPrimary
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 一行：左侧「交易密码」+ 右侧输入框
        passwordLabel.text = "交易密码"
        passwordLabel.font = UIFont.systemFont(ofSize: 16)
        passwordLabel.textColor = Constants.Color.textPrimary
        passwordRow.addSubview(passwordLabel)
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false

        passwordField.placeholder = "请输入交易密码"
        passwordField.font = UIFont.systemFont(ofSize: 16)
        passwordField.textColor = Constants.Color.textPrimary
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .none
        passwordField.clearButtonMode = .whileEditing
        passwordRow.addSubview(passwordField)
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.delegate = self

        underline.backgroundColor = Constants.Color.separator
        passwordRow.addSubview(underline)
        underline.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(passwordRow)
        passwordRow.translatesAutoresizingMaskIntoConstraints = false

        // 确定按钮（红色）
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmButton.backgroundColor = Constants.Color.stockRise
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        contentView.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 16
        let rowH: CGFloat = 50
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleLabel.heightAnchor.constraint(equalToConstant: 28),

            passwordRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            passwordRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            passwordRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            passwordRow.heightAnchor.constraint(equalToConstant: rowH),

            passwordLabel.leadingAnchor.constraint(equalTo: passwordRow.leadingAnchor),
            passwordLabel.centerYAnchor.constraint(equalTo: passwordRow.centerYAnchor),
            passwordLabel.widthAnchor.constraint(equalToConstant: 80),

            passwordField.leadingAnchor.constraint(equalTo: passwordLabel.trailingAnchor, constant: 12),
            passwordField.trailingAnchor.constraint(equalTo: passwordRow.trailingAnchor),
            passwordField.centerYAnchor.constraint(equalTo: passwordRow.centerYAnchor),

            underline.leadingAnchor.constraint(equalTo: passwordRow.leadingAnchor),
            underline.trailingAnchor.constraint(equalTo: passwordRow.trailingAnchor),
            underline.bottomAnchor.constraint(equalTo: passwordRow.bottomAnchor),
            underline.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),

            confirmButton.topAnchor.constraint(equalTo: passwordRow.bottomAnchor, constant: 40),
            confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            confirmButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func confirmTapped() {
        let pwd = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if pwd.isEmpty {
            Toast.showInfo("请输入交易密码")
            return
        }
        // TODO: 调用设置/修改交易密码接口
        self.checkOldpay()
    }
    
    private func checkOldpay() {
        SecureNetworkManager.shared.request(api: Api.checkOldpay_api, method: .post, params: ["paypass": self.password]) { [unowned self] result in
            switch result {
            case .success(let res):
                let dict = res.decrypted
                debugPrint(dict ?? "nil")
                if dict?["code"] as? NSNumber != 1 {
                    DispatchQueue.main.async {
                        Toast.showInfo(dict?["msg"] as? String ?? "")
                    }
                    return
                } else {
                    self.editPass()
                }
            case .failure(let error):
                debugPrint("error =", error.localizedDescription)
                Toast.showError(error.localizedDescription)
            }
        }
    }
    
    private func editPass() {
        SecureNetworkManager.shared.request(api: Api.editPass_api, method: .post, params: ["password": self.password]) { [unowned self] result in
            switch result {
            case .success(let res):
                let dict = res.decrypted
                debugPrint(dict ?? "nil")
                if dict?["code"] as? NSNumber != 1 {
                    DispatchQueue.main.async {
                        Toast.showInfo(dict?["msg"] as? String ?? "")
                    }
                    return
                } else {
                    Toast.showInfo("交易密码设置成功")
                    self.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                debugPrint("error =", error.localizedDescription)
                Toast.showError(error.localizedDescription)
            }
        }
    }
}

extension TransactionPasswordViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.password = textField.text ?? ""
    }
}
