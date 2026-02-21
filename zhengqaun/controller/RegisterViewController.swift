//
//  RegisterViewController.swift
//  zhengqaun
//
//  立即注册 / 开户页面
//

import UIKit
import SafariServices

class RegisterViewController: UIViewController {
    
    private let themeRed = UIColor(red: 230/255, green: 0, blue: 18/255, alpha: 1.0)
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // 状态栏+红色导航头（同色）
    private let statusBarView = UIView()
    private let navBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // 白色卡片
    private let cardView = UIView()
    private let sloganImageView = UIImageView()
    
    private let phoneField = UITextField()
    private let phoneLine = UIView()
    private let passwordField = UITextField()
    private let passwordLine = UIView()
    private let passwordEyeButton = UIButton(type: .custom)
    private let confirmPasswordField = UITextField()
    private let confirmPasswordLine = UIView()
    private let confirmPasswordEyeButton = UIButton(type: .custom)
    private let codeField = UITextField()
    private let codeLine = UIView()
    private let getCodeButton = UIButton(type: .system)
    
    private let submitButton = UIButton(type: .system)
    private let agreementCheckbox = UIButton(type: .custom)
    private let agreementLabel = UILabel()
    
    // 底部准备图
    private let zhunbeiImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Color.backgroundMain
        setupNavBar()
        setupScroll()
        setupCard()
        setupBottomImage()
    }
    
    private func setupNavBar() {
        statusBarView.backgroundColor = themeRed
        view.addSubview(statusBarView)
        statusBarView.translatesAutoresizingMaskIntoConstraints = false
        
        navBarView.backgroundColor = themeRed
        view.addSubview(navBarView)
        navBarView.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        navBarView.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = "立即注册"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        navBarView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            statusBarView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBarView.heightAnchor.constraint(equalToConstant: 56),
            backButton.leadingAnchor.constraint(equalTo: navBarView.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            titleLabel.centerXAnchor.constraint(equalTo: navBarView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBarView.centerYAnchor)
        ])
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    private func setupScroll() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: navBarView.bottomAnchor),
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
    
    private func setupCard() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOpacity = 0.08
        contentView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        // 标语图（slogan 230*62，居中）
        sloganImageView.image = UIImage(named: "slogan")
        sloganImageView.contentMode = .scaleAspectFit
        sloganImageView.clipsToBounds = true
        cardView.addSubview(sloganImageView)
        sloganImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 输入行（手机号、密码、确认密码、验证码）
        addInputRow(container: cardView, field: phoneField, line: phoneLine, icon: "phone", placeholder: "请输入手机号", isSecure: false, rightButton: nil)
        addInputRow(container: cardView, field: passwordField, line: passwordLine, icon: "lock", placeholder: "请输入密码", isSecure: true, rightButton: passwordEyeButton)
        addInputRow(container: cardView, field: confirmPasswordField, line: confirmPasswordLine, icon: "checkmark.shield", placeholder: "请再次输入密码", isSecure: true, rightButton: confirmPasswordEyeButton)
        addInputRow(container: cardView, field: codeField, line: codeLine, icon: "envelope", placeholder: "请输入验证码", isSecure: false, rightButton: getCodeButton)
        
        passwordEyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        passwordEyeButton.setImage(UIImage(systemName: "eye"), for: .selected)
        passwordEyeButton.tintColor = Constants.Color.textTertiary
        passwordEyeButton.addTarget(self, action: #selector(togglePassword1), for: .touchUpInside)
        
        confirmPasswordEyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        confirmPasswordEyeButton.setImage(UIImage(systemName: "eye"), for: .selected)
        confirmPasswordEyeButton.tintColor = Constants.Color.textTertiary
        confirmPasswordEyeButton.addTarget(self, action: #selector(togglePassword2), for: .touchUpInside)
        
        getCodeButton.setTitle("获取验证码", for: .normal)
        getCodeButton.setTitleColor(themeRed, for: .normal)
        getCodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        getCodeButton.addTarget(self, action: #selector(getCodeTapped), for: .touchUpInside)
        
        // 极速开卡按钮
        submitButton.setTitle("极速开卡", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.backgroundColor = themeRed
        submitButton.layer.cornerRadius = 10
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        cardView.addSubview(submitButton)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 协议
        agreementCheckbox.setImage(UIImage(systemName: "square"), for: .normal)
        agreementCheckbox.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        agreementCheckbox.tintColor = themeRed
        agreementCheckbox.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        cardView.addSubview(agreementCheckbox)
        agreementCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        agreementLabel.text = "我同意签署《用户协议》《隐私政策》"
        agreementLabel.font = UIFont.systemFont(ofSize: 12)
        agreementLabel.textColor = Constants.Color.textTertiary
        agreementLabel.numberOfLines = 0
        agreementLabel.isUserInteractionEnabled = true
        cardView.addSubview(agreementLabel)
        agreementLabel.translatesAutoresizingMaskIntoConstraints = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(agreementTapped(_:)))
        agreementLabel.addGestureRecognizer(tap)
        
        layoutCardContent()
    }
    
    private func addInputRow(container: UIView, field: UITextField, line: UIView, icon: String, placeholder: String, isSecure: Bool, rightButton: UIButton?) {
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = Constants.Color.textTertiary
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        field.placeholder = placeholder
        field.font = UIFont.systemFont(ofSize: 15)
        field.textColor = Constants.Color.textPrimary
        field.borderStyle = .none
        field.isSecureTextEntry = isSecure
        field.clearButtonMode = .whileEditing
        if icon == "phone" { field.keyboardType = .phonePad }
        if icon == "envelope" { field.keyboardType = .numberPad }
        container.addSubview(field)
        field.translatesAutoresizingMaskIntoConstraints = false
        
        line.backgroundColor = Constants.Color.separator
        container.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        
        if let btn = rightButton {
            container.addSubview(btn)
            btn.translatesAutoresizingMaskIntoConstraints = false
        }
        
        // 约束在 layoutCardContent 里按顺序统一做
    }
    
    private var cardLayoutDone = false
    
    private func layoutCardContent() {
        guard !cardLayoutDone else { return }
        cardLayoutDone = true
        let allIcons = cardView.subviews.compactMap { $0 as? UIImageView }
        let icons = Array(allIcons.dropFirst()) // 第一个是 slogan 图，后 4 个是输入行图标
        guard icons.count >= 4 else { return }
        
        let cardMargins: CGFloat = 20
        var lastAnchor: NSLayoutYAxisAnchor = sloganImageView.bottomAnchor
        let rowHeight: CGFloat = 44
        let lineH: CGFloat = 1
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            sloganImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            sloganImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            sloganImageView.widthAnchor.constraint(equalToConstant: 230),
            sloganImageView.heightAnchor.constraint(equalToConstant: 62)
        ])
        let rowSpacing: CGFloat = 20
        for i in 0..<4 {
            let iconView = icons[i]
            let field = [phoneField, passwordField, confirmPasswordField, codeField][i]
            let line = [phoneLine, passwordLine, confirmPasswordLine, codeLine][i]
            var constraints: [NSLayoutConstraint] = [
                iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
                iconView.centerYAnchor.constraint(equalTo: field.centerYAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 22),
                iconView.heightAnchor.constraint(equalToConstant: 22),
                field.topAnchor.constraint(equalTo: lastAnchor, constant: i == 0 ? 24 : rowSpacing),
                field.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
                field.heightAnchor.constraint(equalToConstant: rowHeight),
                line.topAnchor.constraint(equalTo: field.bottomAnchor),
                line.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
                line.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
                line.heightAnchor.constraint(equalToConstant: lineH)
            ]
            if i == 1 {
                constraints.append(passwordEyeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins))
                constraints.append(passwordEyeButton.centerYAnchor.constraint(equalTo: passwordField.centerYAnchor))
                constraints.append(passwordEyeButton.widthAnchor.constraint(equalToConstant: 44))
                constraints.append(field.trailingAnchor.constraint(equalTo: passwordEyeButton.leadingAnchor, constant: -8))
            } else if i == 2 {
                constraints.append(confirmPasswordEyeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins))
                constraints.append(confirmPasswordEyeButton.centerYAnchor.constraint(equalTo: confirmPasswordField.centerYAnchor))
                constraints.append(confirmPasswordEyeButton.widthAnchor.constraint(equalToConstant: 44))
                constraints.append(field.trailingAnchor.constraint(equalTo: confirmPasswordEyeButton.leadingAnchor, constant: -8))
            } else if i == 3 {
                constraints.append(getCodeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins))
                constraints.append(getCodeButton.centerYAnchor.constraint(equalTo: codeField.centerYAnchor))
                constraints.append(getCodeButton.widthAnchor.constraint(equalToConstant: 90))
                constraints.append(field.trailingAnchor.constraint(equalTo: getCodeButton.leadingAnchor, constant: -8))
            } else {
                constraints.append(field.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins))
            }
            NSLayoutConstraint.activate(constraints)
            lastAnchor = line.bottomAnchor
        }
        
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: lastAnchor, constant: 28),
            submitButton.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
            submitButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
            submitButton.heightAnchor.constraint(equalToConstant: 50),
            
            agreementCheckbox.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: cardMargins),
            agreementCheckbox.centerYAnchor.constraint(equalTo: agreementLabel.centerYAnchor),
            agreementCheckbox.widthAnchor.constraint(equalToConstant: 22),
            agreementCheckbox.heightAnchor.constraint(equalToConstant: 22),
            agreementLabel.leadingAnchor.constraint(equalTo: agreementCheckbox.trailingAnchor, constant: 8),
            agreementLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -cardMargins),
            agreementLabel.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 16),
            agreementLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func togglePassword1() {
        passwordEyeButton.isSelected.toggle()
        passwordField.isSecureTextEntry = !passwordEyeButton.isSelected
    }
    
    @objc private func togglePassword2() {
        confirmPasswordEyeButton.isSelected.toggle()
        confirmPasswordField.isSecureTextEntry = !confirmPasswordEyeButton.isSelected
    }
    
    @objc private func getCodeTapped() {
        let phone = phoneField.text ?? ""
        guard !phone.isEmpty else {
            Toast.show("请输入手机号")
            return
        }
        Toast.showSuccess("验证码已发送")
        var count = 60
        getCodeButton.isEnabled = false
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
            count -= 1
            if count > 0 {
                self?.getCodeButton.setTitle("\(count)秒", for: .normal)
            } else {
                t.invalidate()
                self?.getCodeButton.isEnabled = true
                self?.getCodeButton.setTitle("获取验证码", for: .normal)
            }
        }
    }
    
    @objc private func checkboxTapped() {
        agreementCheckbox.isSelected.toggle()
    }
    
    @objc private func agreementTapped(_ g: UITapGestureRecognizer) {
        openAgreement(url: "https://www.htsc.com.cn/user-agreement")
    }
    
    private func openAgreement(url: String) {
        guard let u = URL(string: url) else { return }
        let vc = SFSafariViewController(url: u)
        vc.preferredControlTintColor = themeRed
        present(vc, animated: true)
    }
    
    @objc private func submitTapped() {
        guard agreementCheckbox.isSelected else {
            Toast.show("请先同意用户协议和隐私政策")
            return
        }
        let phone = phoneField.text ?? ""
        let pwd = passwordField.text ?? ""
        let confirm = confirmPasswordField.text ?? ""
        let code = codeField.text ?? ""
        guard !phone.isEmpty, !pwd.isEmpty, !confirm.isEmpty, !code.isEmpty else {
            Toast.show("请填写完整信息")
            return
        }
        guard pwd == confirm else {
            Toast.showError("两次密码不一致")
            return
        }
        // 可在此调用注册接口
        Toast.showSuccess("提交成功")
        dismiss(animated: true)
    }
    
    private func setupBottomImage() {
        zhunbeiImageView.image = UIImage(named: "zhunbei")
        zhunbeiImageView.contentMode = .scaleAspectFit
        zhunbeiImageView.clipsToBounds = true
        contentView.addSubview(zhunbeiImageView)
        zhunbeiImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            zhunbeiImageView.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 32),
            zhunbeiImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            zhunbeiImageView.widthAnchor.constraint(equalToConstant: 267),
            zhunbeiImageView.heightAnchor.constraint(equalToConstant: 78),
            zhunbeiImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32)
        ])
    }
}
