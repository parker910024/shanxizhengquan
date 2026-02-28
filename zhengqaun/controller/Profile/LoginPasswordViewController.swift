//
//  LoginPasswordViewController.swift
//  zhengqaun
//
//  修改登录密码页面（对齐安卓 ChangeLoginPwdActivity）
//  流程：原密码 + 新密码 + 确认新密码 → editPass1 API
//

import UIKit

class LoginPasswordViewController: ZQViewController {

    private let contentView = UIView()
    private let sectionTitleLabel = UILabel()

    // 三行输入（对齐安卓）
    private let oldPassField = UITextField()
    private let newPassField = UITextField()
    private let confirmPassField = UITextField()

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
        gk_navTitle = "登录密码"
        gk_navLineHidden = false
        gk_backStyle = .black
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        let margin: CGFloat = 16

        // 大标题：修改登录密码
        sectionTitleLabel.text = "修改登录密码"
        sectionTitleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        sectionTitleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        contentView.addSubview(sectionTitleLabel)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // 输入行（对齐安卓 activity_change_login_pwd.xml）
        let row1 = makeInputRow(label: "原登录密码", field: oldPassField, placeholder: "请输入原登录密码")
        let divider1 = makeDivider()
        let row2 = makeInputRow(label: "新登录密码", field: newPassField, placeholder: "请输入新登录密码")
        let divider2 = makeDivider()
        let row3 = makeInputRow(label: "确认新密码", field: confirmPassField, placeholder: "请确认新登录密码")
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

            // 第一行：原登录密码
            row1.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 24),
            row1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            row1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            row1.heightAnchor.constraint(equalToConstant: rowH),

            divider1.topAnchor.constraint(equalTo: row1.bottomAnchor),
            divider1.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            divider1.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            divider1.heightAnchor.constraint(equalToConstant: 0.5),

            // 第二行：新登录密码
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

        field.placeholder = placeholder
        field.font = UIFont.systemFont(ofSize: 15)
        field.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        field.textAlignment = .right
        field.isSecureTextEntry = true
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

    // MARK: - 提交（对齐安卓 ChangeLoginPwdActivity 流程）

    @objc private func confirmTapped() {
        let oldPass = oldPassField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let newPass = newPassField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirmPass = confirmPassField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty {
            Toast.showInfo("请填写所有密码字段")
            return
        }
        if newPass != confirmPass {
            Toast.showInfo("两次输入的密码不一致")
            return
        }

        confirmButton.isEnabled = false

        // 对齐安卓：调用 editPass1 API，参数 oldpass/password/confimpassword
        SecureNetworkManager.shared.request(
            api: Api.editPass1_api,
            method: .post,
            params: [
                "oldpass": oldPass,
                "password": newPass,
                "confimpassword": confirmPass
            ]
        ) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.confirmButton.isEnabled = true
            }
            switch result {
            case .success(let res):
                let dict = res.decrypted
                if dict?["code"] as? NSNumber != 1 {
                    DispatchQueue.main.async {
                        Toast.showInfo(dict?["msg"] as? String ?? "修改失败")
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
