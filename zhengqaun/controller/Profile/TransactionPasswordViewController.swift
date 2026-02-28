//
//  TransactionPasswordViewController.swift
//  zhengqaun
//
//  设置/修改交易密码页面（对齐安卓 ChangeTradePwdActivity）
//  流程：验证原支付密码(checkOldpay) → 新密码与确认一致后修改(editPass)
//

import UIKit

class TransactionPasswordViewController: ZQViewController {

    private let contentView = UIView()
    private let sectionTitleLabel = UILabel()

    // 三行输入
    private let oldPayField = UITextField()
    private let newPayField = UITextField()
    private let confirmPayField = UITextField()

    private let confirmButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupUI()

        // 点击空白收键盘
        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
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

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 16

        // 大标题：设置交易密码
        sectionTitleLabel.text = "设置交易密码"
        sectionTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        sectionTitleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        contentView.addSubview(sectionTitleLabel)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 输入行
        let row1 = makeInputRow(label: "原支付密码", field: oldPayField, placeholder: "请输入交易密码")
        let divider1 = makeDivider()
        let row2 = makeInputRow(label: "新支付密码", field: newPayField, placeholder: "请输入交易密码")
        let divider2 = makeDivider()
        let row3 = makeInputRow(label: "确认新密码", field: confirmPayField, placeholder: "请输入交易密码")
        let divider3 = makeDivider()

        contentView.addSubview(row1)
        contentView.addSubview(divider1)
        contentView.addSubview(row2)
        contentView.addSubview(divider2)
        contentView.addSubview(row3)
        contentView.addSubview(divider3)

        // 确定按钮（红色，对齐安卓 bg_btn_red）
        confirmButton.setTitle("确定", for: .normal)
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmButton.backgroundColor = Constants.Color.stockRise
        confirmButton.layer.cornerRadius = 8
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        contentView.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        let rowH: CGFloat = 48

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.Navigation.totalNavigationHeight),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // 标题
            sectionTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),

            // 第一行：原支付密码
            row1.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 24),
            row1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            row1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            row1.heightAnchor.constraint(equalToConstant: rowH),

            divider1.topAnchor.constraint(equalTo: row1.bottomAnchor),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            divider1.heightAnchor.constraint(equalToConstant: 0.5),

            // 第二行：新支付密码
            row2.topAnchor.constraint(equalTo: divider1.bottomAnchor),
            row2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            row2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            row2.heightAnchor.constraint(equalToConstant: rowH),

            divider2.topAnchor.constraint(equalTo: row2.bottomAnchor),
            divider2.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            divider2.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            divider2.heightAnchor.constraint(equalToConstant: 0.5),

            // 第三行：确认新密码
            row3.topAnchor.constraint(equalTo: divider2.bottomAnchor),
            row3.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            row3.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            row3.heightAnchor.constraint(equalToConstant: rowH),

            divider3.topAnchor.constraint(equalTo: row3.bottomAnchor),
            divider3.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            divider3.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            divider3.heightAnchor.constraint(equalToConstant: 0.5),

            // 确定按钮
            confirmButton.topAnchor.constraint(equalTo: divider3.bottomAnchor, constant: 48),
            confirmButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
            confirmButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            confirmButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    // MARK: - 构建输入行（左标签 + 右输入框）

    private func makeInputRow(label: String, field: UITextField, placeholder: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        row.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        field.setZqPlaceholder(placeholder)
        field.font = UIFont.systemFont(ofSize: 15)
        field.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        field.textAlignment = .right
        field.isSecureTextEntry = true
        field.keyboardType = .numberPad
        field.borderStyle = .none
        row.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            field.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    // MARK: - 提交（对齐安卓 ChangeTradePwdActivity 流程）

    @objc private func confirmTapped() {
        let oldPay = oldPayField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let newPay = newPayField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirmPay = confirmPayField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if oldPay.isEmpty {
            Toast.showInfo("请输入交易密码")
            return
        }
        if oldPay.count != 6 {
            Toast.showInfo("支付密码需要6位数字")
            return
        }
        if newPay.isEmpty || confirmPay.isEmpty {
            Toast.showInfo("请输入新支付密码")
            return
        }
        if newPay.count != 6 {
            Toast.showInfo("新支付密码需要6位数字")
            return
        }
        if newPay != confirmPay {
            Toast.showInfo("两次输入的密码不一致")
            return
        }

        confirmButton.isEnabled = false
        checkOldpay(oldPassword: oldPay, newPassword: newPay)
    }

    // 验证原支付密码
    private func checkOldpay(oldPassword: String, newPassword: String) {
        SecureNetworkManager.shared.request(api: Api.checkOldpay_api, method: .post, params: ["paypass": oldPassword]) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let res):
                let dict = res.decrypted
                if dict?["code"] as? NSNumber != 1 {
                    DispatchQueue.main.async {
                        Toast.showInfo("原支付密码不正确")
                        self.oldPayField.text = ""
                        self.confirmButton.isEnabled = true
                    }
                    return
                }
                // 原密码验证通过，修改密码
                self.editPass(newPassword: newPassword)
            case .failure(let error):
                DispatchQueue.main.async {
                    self.confirmButton.isEnabled = true
                    Toast.showError(error.localizedDescription)
                }
            }
        }
    }

    // 修改密码
    private func editPass(newPassword: String) {
        SecureNetworkManager.shared.request(api: Api.editPass_api, method: .post, params: ["password": newPassword]) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.confirmButton.isEnabled = true
            }
            switch result {
            case .success(let res):
                let dict = res.decrypted
                if dict?["code"] as? NSNumber != 1 {
                    DispatchQueue.main.async {
                        Toast.showInfo(dict?["msg"] as? String ?? "")
                    }
                    return
                }
                DispatchQueue.main.async {
                    // 对齐安卓：弹出提示框，确认后返回
                    let alert = UIAlertController(title: "提示", message: "修改成功", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    Toast.showError(error.localizedDescription)
                }
            }
        }
    }
}
